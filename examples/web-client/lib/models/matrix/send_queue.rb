# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # ── The send queue ──────────────────────────────────────────────────────
    #
    # Matrix::Device::Session's comment makes the old position explicit: "a
    # sent message is not done until the homeserver echoes it back", so
    # nothing was stored between the POST and the echo. That is correct about
    # truth and wrong about the interface -- it means a message cannot be
    # shown as sending, cannot be retried after a failure, and is simply lost
    # if the process dies mid-send.
    #
    # This table does not change where truth lives. matrix_events is still
    # written only by sync. This is the OUTBOX: rows go in when the user hits
    # send, come out when the echo arrives, and `wedge_reason` is where a send
    # that cannot proceed records why instead of disappearing.
    class SendQueue < Sequel::Model(:matrix_send_queue)
      # Higher goes first. Named so the call sites do not spell the numbers --
      # the only thing that matters is the order between them.
      PRIORITY_BULK      = -10
      PRIORITY_DEFAULT   = 0
      PRIORITY_IMMEDIATE = 10

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :content, :wedge_reason

      def validate
        super
        validates_presence %i[room_id transaction_id event_type]
        validates_unique %i[user_id room_id transaction_id]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)

        # Still sendable: nothing has wedged it. This is the queue the sender
        # drains, in the order the covering index is built for.
        def sendable = where(wedge_reason: nil).order(Sequel.desc(:priority), :enqueued_at)

        def wedged = exclude(wedge_reason: nil)
      end

      def wedged? = !wedge_reason.nil?

      # Park a send that cannot proceed unattended, with the reason a UI can
      # show. The row STAYS -- that is the point of the table.
      def wedge!(reason)
        update(wedge_reason: reason)
      end

      # The user said try again. Clears the reason and nothing else, so the row
      # keeps its place in the queue.
      def unwedge!
        update(wedge_reason: nil)
      end

      # Sends parked against this one, waiting for its event_id.
      def dependents
        SendQueueDependent.where(user_id: user_id, parent_transaction_id: transaction_id)
      end

      # The local echo in matrix_events, if sync has not replaced it yet.
      def local_echo
        Event.first(user_id: user_id, transaction_id: transaction_id)
      end
    end
  end
end

__END__

create_table?(:matrix_send_queue) do
  primary_key :id, type: :Bignum, serial: true
  column      :user_id, :bigint, null: false
  column      :room_id, TEXT, null: false
  # Ours, generated before the request, and the only handle on this
  # message until the homeserver assigns an event_id.
  column      :transaction_id, TEXT, null: false
  column      :event_type, TEXT, null: false
  column      :content, :blob, default: Sequel.lit("jsonb('{}')"), null: false
  # Higher goes first. Reactions and receipts should not queue behind a
  # 40MB video.
  column      :priority, :integer, default: 0, null: false
  # Set when the send cannot proceed unattended -- a cross-signing
  # verification required, an unknown device in the room, a 403. Nil
  # means still sendable.
  column      :wedge_reason, :blob
  column      :enqueued_at, TIMESTAMP, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[user_id room_id transaction_id],
    unique: true,
    name:   :index_matrix_send_queue_on_user_id_and_room_id_and_txn_id
  index %i[user_id priority enqueued_at],
    name: :index_matrix_send_queue_on_user_id_and_priority_and_enqueued
end
