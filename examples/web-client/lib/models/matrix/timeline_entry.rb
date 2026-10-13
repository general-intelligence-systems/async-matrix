# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class TimelineEntry < Sequel::Model(:matrix_timeline_entries)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[room_id chunk_id event_id position]
        validates_unique %i[room_id thread_root_id chunk_id position]
        validates_unique %i[room_id thread_root_id event_id]
      end

      dataset_module do
        def in_timeline(room_id, thread_root_id = TimelineChunk::MAIN)
          where(room_id: room_id, thread_root_id: thread_root_id)
        end

        def in_chunk(chunk_id) = where(chunk_id: chunk_id)
        def ordered            = order(:chunk_id, :position)
      end

      def event
        Event.first(event_id: event_id)
      end
    end
  end
end

__END__

create_table?(:matrix_timeline_entries) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :thread_root_id, TEXT, default: "", null: false
  column      :chunk_id, :integer, null: false
  column      :event_id, TEXT, null: false
  column      :position, :integer, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id thread_root_id chunk_id position],
    unique: true,
    name:   :index_matrix_timeline_entries_on_room_id_and_thread_root_id_and_chunk_id_and_position
  # An event cannot be in the same timeline twice.
  index %i[room_id thread_root_id event_id],
    unique: true,
    name:   :index_matrix_timeline_entries_on_room_id_and_thread_root_id_and_event_id
end
