# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # Sends that depend on a send that has not landed yet.
    #
    # Reacting to, editing or redacting a message that is still in the queue
    # is a normal thing for a person to do, and it cannot be expressed as a
    # queued event: the content needs an event_id that does not exist. So the
    # dependent is parked here against its parent's transaction id, and is
    # promoted into matrix_send_queue once the parent's echo supplies the
    # event_id (`parent_key`).
    class SendQueueDependent < Sequel::Model(:matrix_send_queue_dependents)
      # What to do with the parent once it exists. The migration's comment
      # carries the same four.
      REACT       = "react"
      EDIT        = "edit"
      REDACT      = "redact"
      UPLOAD_FILE = "upload_file"
      KINDS       = [REACT, EDIT, REDACT, UPLOAD_FILE].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :parent_key, :content

      def validate
        super
        validates_presence %i[room_id parent_transaction_id own_transaction_id]
        validates_includes KINDS, :kind
        validates_unique %i[user_id own_transaction_id]
      end

      dataset_module do
        def of_parent(transaction_id) = where(parent_transaction_id: transaction_id)

        # Ready to be promoted into the queue: the echo has supplied the
        # parent's event_id.
        def resolved = exclude(parent_key: nil)
        def pending  = where(parent_key: nil)
      end

      def resolved? = !parent_key.nil?

      # The echo landed. Records the parent's event_id, which is the one thing
      # this row was waiting for.
      def resolve!(parent_key)
        update(parent_key: parent_key)
      end

      # The queued send this one is parked against, while it is still queued.
      def parent
        SendQueue.first(
          user_id:        user_id,
          room_id:        room_id,
          transaction_id: parent_transaction_id,
        )
      end
    end
  end
end

__END__

create_table?(:matrix_send_queue_dependents) do
  primary_key :id, type: :Bignum, serial: true
  column      :user_id, :bigint, null: false
  column      :room_id, TEXT, null: false
  column      :parent_transaction_id, TEXT, null: false
  column      :own_transaction_id, TEXT, null: false
  # The parent's event_id, once known. Nil until the echo.
  column      :parent_key, :blob
  # "react" / "edit" / "redact" / "upload_file" -- what to do with the
  # parent once it exists.
  column      :kind, TEXT, null: false
  column      :content, :blob, default: Sequel.lit("jsonb('{}')"), null: false
  column      :enqueued_at, TIMESTAMP, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[user_id own_transaction_id],
    unique: true,
    name:   :index_matrix_send_queue_dependents_on_user_id_and_own_txn_id
  index %i[user_id parent_transaction_id],
    name: :index_matrix_send_queue_dependents_on_user_id_and_parent_txn
end
