# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # ── The timeline, as a chunked linked list ──────────────────────────────
    #
    # THIS IS THE PART THAT CANNOT BE FAKED WITH A TIMESTAMP SORT, and it is
    # the single biggest omission in the ten tables. matrix_events ordered by
    # origin_server_ts renders a plausible timeline and silently lies about
    # it: a /sync with `limited: true` means the server skipped events, and
    # nothing in a flat table records that the messages either side of the
    # skip are not adjacent. The user scrolls up and the history is simply
    # wrong, with no way to detect it after the fact.
    #
    # So the SDK's model is borrowed wholesale: a room's timeline is a doubly
    # linked list of chunks, each chunk either a run of events or a GAP
    # holding the token to paginate it away. Filling a gap is a /messages
    # call with its `prev_token`; the gap chunk is then replaced by an event
    # chunk and the list is spliced. A timeline is complete when it contains
    # no gaps, and that is a query rather than a hope.
    #
    # `thread_root_id` is the SDK's LinkedChunkId: the main timeline is "",
    # and a thread gets its own chunk list under its root event. Same reason
    # as the other "" defaults -- it is half of every key here.
    class TimelineChunk < Sequel::Model(:matrix_timeline_chunks)
      # The two kinds, spelled out. The CHECK constraint in the migration
      # carries the same pair, so a bad value fails at the database too.
      EVENT = "event"
      GAP   = "gap"
      KINDS = [EVENT, GAP].freeze

      # The main timeline's LinkedChunkId. A thread's is its root event id.
      MAIN = ""

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[room_id chunk_id]
        validates_includes KINDS, :kind
        validates_unique %i[room_id thread_root_id chunk_id]
      end

      dataset_module do
        def in_timeline(room_id, thread_root_id = MAIN)
          where(room_id: room_id, thread_root_id: thread_root_id)
        end

        def gaps   = where(kind: GAP)
        def events = where(kind: EVENT)

        # The head of the list: the only chunk nothing points back to.
        def first_chunk = where(previous_chunk_id: nil)
        def last_chunk  = where(next_chunk_id: nil)
      end

      def gap? = kind == GAP

      # A timeline with no gaps is complete, and this is what makes that a query
      # rather than a hope -- see the class comment.
      def self.complete?(room_id:, thread_root_id: MAIN)
        where(
          room_id:        room_id,
          thread_root_id: thread_root_id,
          kind:           GAP,
        ).empty?
      end

      # The chunks either side of this one, by chunk_id rather than row id.
      def previous_chunk = sibling(previous_chunk_id)
      def next_chunk     = sibling(next_chunk_id)

      # The events in this chunk, in order.
      def entries
        TimelineEntry
          .where(
            room_id:        room_id,
            thread_root_id: thread_root_id,
            chunk_id:       chunk_id,
          )
          .order(:position)
      end

      private

      def sibling(id)
        if id.nil?
          nil
        else
          self.class.first(
            room_id:        room_id,
            thread_root_id: thread_root_id,
            chunk_id:       id,
          )
        end
      end
    end
  end
end

__END__

create_table?(:matrix_timeline_chunks) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :thread_root_id, TEXT, default: "", null: false
  # Not the primary key: chunk ids are assigned per timeline and the
  # linked list refers to them, so they have to survive independently
  # of the row id.
  column      :chunk_id, :integer, null: false
  column      :previous_chunk_id, :integer
  column      :next_chunk_id, :integer
  # "event" or "gap". The SDK spells these 'E' and 'G' in a CHECK
  # constraint; spelled out here because nothing about this table is
  # hot enough to care and 'G' reads as nothing at all.
  column      :kind, TEXT, null: false
  # Set only on a gap: the token /messages needs to fill it.
  column      :prev_token, :text
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  constraint :matrix_timeline_chunks_kind, kind: %w[event gap]

  index %i[room_id thread_root_id chunk_id],
    unique: true,
    name:   :index_matrix_timeline_chunks_on_room_id_and_thread_root_id_and_chunk_id
  index %i[room_id thread_root_id kind],
    name:   :index_matrix_timeline_chunks_on_room_id_and_thread_root_id_and_kind
end
