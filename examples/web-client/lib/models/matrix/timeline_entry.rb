# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # Which events sit in which chunk, and in what order.
    #
    # SEPARATE FROM matrix_events ON PURPOSE. One event can appear in more
    # than one timeline -- the room's main timeline and a thread's -- at
    # different positions, so position cannot live on the event. It is also
    # what lets the event rows be rewritten (a late decryption, an edit)
    # without touching the ordering.
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

      # The event this entry points at. A JOIN rather than an association
      # because the key is (user_id, event_id) and not a foreign key -- see the
      # migration for why there are none.
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
