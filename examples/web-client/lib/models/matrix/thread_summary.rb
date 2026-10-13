# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class ThreadSummary < Sequel::Model(:matrix_thread_summaries)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :info

      def validate
        super
        validates_presence %i[room_id event_id]
        validates_unique %i[room_id event_id]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)

        def by_latest_reply
          order(Sequel.lit(<<~SQL))
            (SELECT origin_server_ts FROM matrix_events
              WHERE matrix_events.event_id = matrix_thread_summaries.latest_reply_id)
            DESC NULLS LAST
          SQL
        end
      end

      def root
        Event.first(event_id: event_id)
      end

      def replies
        Event.where(room_id: room_id).in_thread(event_id).chronological
      end

      def subscription
        ThreadSubscription.first(room_id: room_id, event_id: event_id)
      end

      def latest_reply
        Event.first(event_id: latest_reply_id)
      end
    end
  end
end

__END__

create_table?(:matrix_thread_summaries) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  # The thread root's event id.
  column      :event_id, TEXT, null: false
  # ThreadInfo in full, as the SDK stores it.
  column      :info, :blob, default: Sequel.lit("'{}'"), null: false
  # Hoisted out of `info` because the thread list sorts and counts on them.
  column      :latest_reply_id, TEXT
  column      :reply_count, :integer, default: 0, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id event_id],
    unique: true,
    name:   :index_matrix_thread_summaries_on_room_id_and_event_id
end
