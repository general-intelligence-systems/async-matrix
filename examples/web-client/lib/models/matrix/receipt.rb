# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class Receipt < Sequel::Model(:matrix_receipts)
      TYPES = %w[m.read m.read.private].freeze

      MAIN = "main"

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[room_id member_id event_id]
        validates_includes TYPES, :receipt_type
        validates_unique %i[room_id member_id receipt_type thread_id]
      end

      dataset_module do
        def in_room(room_id)   = where(room_id: room_id)
        def of_member(member_id) = where(member_id: member_id)
        def unthreaded         = where(thread_id: MAIN)
        def in_thread(root_id) = where(thread_id: root_id)

        def on_event(event_id) = where(event_id: event_id)
      end
    end
  end
end

__END__

create_table?(:matrix_receipts) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  # The member whose receipt this is -- ours or anyone else's. Named
  # member_id to match matrix_room_members.
  column      :member_id, TEXT, null: false
  column      :receipt_type, TEXT, default: "m.read", null: false
  column      :thread_id, TEXT, default: "main", null: false
  column      :event_id, TEXT, null: false
  column      :receipt_ts, :bigint
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id member_id receipt_type thread_id],
    unique: true,
    name:   :index_matrix_receipts_on_room_id_and_member_id_and_receipt_type_and_thread_id
  index %i[room_id event_id], name: :index_matrix_receipts_on_room_id_and_event_id
end
