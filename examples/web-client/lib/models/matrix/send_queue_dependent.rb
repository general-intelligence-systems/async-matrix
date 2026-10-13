# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class SendQueueDependent < Sequel::Model(:matrix_send_queue_dependents)
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
        validates_unique :own_transaction_id
      end

      dataset_module do
        def of_parent(transaction_id) = where(parent_transaction_id: transaction_id)

        def resolved = exclude(parent_key: nil)
        def pending  = where(parent_key: nil)
      end

      def resolved? = !parent_key.nil?

      def resolve!(parent_key)
        update(parent_key: parent_key)
      end

      def parent
        SendQueue.first(
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
  column      :room_id, TEXT, null: false
  column      :parent_transaction_id, TEXT, null: false
  column      :own_transaction_id, TEXT, null: false
  # The parent's event_id, once known. Nil until the echo.
  column      :parent_key, :blob
  # "react" / "edit" / "redact" / "upload_file" -- what to do with the
  # parent once it exists.
  column      :kind, TEXT, null: false
  column      :content, :blob, default: Sequel.lit("'{}'"), null: false
  column      :enqueued_at, TIMESTAMP, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :own_transaction_id,
    unique: true,
    name:   :index_matrix_send_queue_dependents_on_own_transaction_id
  index :parent_transaction_id, name: :index_matrix_send_queue_dependents_on_parent_transaction_id
end
