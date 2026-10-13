# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class SendQueue < Sequel::Model(:matrix_send_queue)
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
        validates_unique %i[room_id transaction_id]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)

        def sendable = where(wedge_reason: nil).order(Sequel.desc(:priority), :enqueued_at)

        def wedged = exclude(wedge_reason: nil)
      end

      def wedged? = !wedge_reason.nil?

      def wedge!(reason)
        update(wedge_reason: reason)
      end

      def unwedge!
        update(wedge_reason: nil)
      end

      def dependents
        SendQueueDependent.where(parent_transaction_id: transaction_id)
      end
    end
  end
end

__END__

create_table?(:matrix_send_queue) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  # Ours, generated before the request, and the only handle on this
  # message until the homeserver assigns an event_id.
  column      :transaction_id, TEXT, null: false
  column      :event_type, TEXT, null: false
  column      :content, :blob, default: Sequel.lit("'{}'"), null: false
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

  index %i[room_id transaction_id],
    unique: true,
    name:   :index_matrix_send_queue_on_room_id_and_transaction_id
  index %i[priority enqueued_at], name: :index_matrix_send_queue_on_priority_and_enqueued_at
end
