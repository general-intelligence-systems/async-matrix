# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # What a thread looks like from the outside: its root, and the summary a
    # room's thread list renders without opening any of them.
    #
    # The SDK's `threads` table, which exists there for a reason worth
    # repeating: a thread has a timeline of its own, so its chunks are keyed by
    # a LinkedChunkId::Thread rather than a room, and that key is hashed and
    # cannot be decoded. The table is the way back -- given a room, find its
    # threads; given a thread, find its root event and its ThreadInfo.
    #
    # HERE THE MAPPING IS NOT THE POINT, because nothing is hashed:
    # TimelineChunk is keyed by (room_id, thread_root_id) and a thread's chunks
    # are already reachable. What is still needed is the SUMMARY -- `info`,
    # the SDK's ThreadInfo -- which is the latest reply and the reply count, and
    # is not derivable without counting the thread's events on every render.
    #
    # DISTINCT FROM ThreadSubscription, which is whether we follow the thread.
    # A thread we have never subscribed to still has a summary; a thread we have
    # unsubscribed from still has one.
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

        # The thread list's order: whichever thread was last replied to.
        def by_latest_reply = order(Sequel.lit("latest_reply_ts DESC NULLS LAST"))
      end

      # The thread root.
      def root
        Event.first(event_id: event_id)
      end

      # Its replies, in order.
      def replies
        Event.where(room_id: room_id).in_thread(event_id).chronological
      end

      # Whether we follow it, which lives in its own table.
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
  column      :latest_reply_ts, :bigint
  column      :reply_count, :integer, default: 0, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id event_id],
    unique: true,
    name:   :index_matrix_thread_summaries_on_room_id_and_event_id
  index %i[room_id latest_reply_ts],
    name: :index_matrix_thread_summaries_on_room_id_and_latest_reply_ts
end
