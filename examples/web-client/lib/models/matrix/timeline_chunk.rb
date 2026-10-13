# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class TimelineChunk < Sequel::Model(:matrix_timeline_chunks)
      EVENT = "event"
      GAP   = "gap"
      KINDS = [EVENT, GAP].freeze

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

        def first_chunk = where(previous_chunk_id: nil)
        def last_chunk  = where(next_chunk_id: nil)
      end

      def gap? = kind == GAP

      def self.complete?(room_id:, thread_root_id: MAIN)
        where(
          room_id:        room_id,
          thread_root_id: thread_root_id,
          kind:           GAP,
        ).empty?
      end

      def previous_chunk = sibling(previous_chunk_id)
      def next_chunk     = sibling(next_chunk_id)

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
