# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class ThreadSubscription < Sequel::Model(:matrix_thread_subscriptions)
      SUBSCRIBED   = "subscribed"
      UNSUBSCRIBED = "unsubscribed"
      STATUSES     = [SUBSCRIBED, UNSUBSCRIBED].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[room_id event_id]
        validates_includes STATUSES, :status
        validates_unique %i[room_id event_id]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)
        def subscribed      = where(status: SUBSCRIBED)

        def by_bump_stamp = order(Sequel.lit("bump_stamp DESC NULLS LAST"))
      end

      def subscribed? = status == SUBSCRIBED

      def root
        Event.first(event_id: event_id)
      end

      def replies
        Event.where(room_id: room_id).in_thread(event_id)
      end
    end
  end
end

__END__

create_table?(:matrix_thread_subscriptions) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  # The thread root.
  column      :event_id, TEXT, null: false
  column      :status, TEXT, null: false
  column      :bump_stamp, :bigint
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id event_id],
    unique: true,
    name:   :index_matrix_thread_subscriptions_on_room_id_and_event_id
end
