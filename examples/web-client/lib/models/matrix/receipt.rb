# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # Read receipts.
    #
    # `thread_id` is "main" for the unthreaded receipt rather than NULL --
    # MSC3771 made receipts thread-scoped, "main" is the spec's own name for
    # the unthreaded timeline, and it keeps the unique index total.
    class Receipt < Sequel::Model(:matrix_receipts)
      # The spec's receipt types. m.read is public, m.read.private is the one
      # the homeserver does not broadcast, and m.fully_read is the MARKER --
      # which is account data, not a receipt, and so never appears here.
      TYPES = %w[m.read m.read.private].freeze

      # MSC3771's name for the unthreaded timeline. NOT nil -- see the class
      # comment.
      MAIN = "main"

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[room_id member_id event_id]
        validates_includes TYPES, :receipt_type
        validates_unique %i[user_id room_id member_id receipt_type thread_id]
      end

      dataset_module do
        def in_room(room_id)   = where(room_id: room_id)
        def of_member(member_id) = where(member_id: member_id)
        def unthreaded         = where(thread_id: MAIN)
        def in_thread(root_id) = where(thread_id: root_id)

        # Everyone who has read a given event, which is the query that draws the
        # read avatars under a message.
        def on_event(event_id) = where(event_id: event_id)
      end
    end
  end
end

__END__

create_table?(:matrix_receipts) do
  primary_key :id, type: :Bignum, serial: true
  column      :user_id, :bigint, null: false
  column      :room_id, TEXT, null: false
  # The member whose receipt this is -- ours or anyone else's. Named
  # member_id to match matrix_room_members rather than `user_id`, which
  # in this schema is always the local account.
  column      :member_id, TEXT, null: false
  column      :receipt_type, TEXT, default: "m.read", null: false
  column      :thread_id, TEXT, default: "main", null: false
  column      :event_id, TEXT, null: false
  column      :receipt_ts, :bigint
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[user_id room_id member_id receipt_type thread_id],
    unique: true,
    name:   :index_matrix_receipts_on_user_id_and_room_and_member_and_type
  index %i[user_id room_id event_id],
    name: :index_matrix_receipts_on_user_id_and_room_id_and_event_id
end
