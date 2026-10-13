# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class RoomState < Sequel::Model(:matrix_room_state)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :content, :prev_content

      def validate
        super
        validates_presence %i[room_id event_type]
        validates_unique %i[room_id event_type state_key]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)
        def of_type(type)    = where(event_type: type)

        def singular(type) = where(event_type: type, state_key: "")

        def stripped = where(stripped: true)
        def synced   = where(stripped: false)
      end

      def stripped? = !!stripped

      def self.content_for(room_id:, event_type:, state_key: "")
        first(
          room_id:    room_id,
          event_type: event_type,
          state_key:  state_key,
        )&.content
      end
    end
  end
end

__END__

create_table?(:matrix_room_state) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :event_type, TEXT, null: false
  # "" is a real state key and the common one, so this is NOT NULL with
  # an empty default rather than nullable -- a nullable column here
  # would put the rows the unique index exists to deduplicate outside
  # it, since SQLite treats NULLs as distinct.
  column      :state_key, TEXT, default: "", null: false
  column      :stripped, :boolean, default: false, null: false
  column      :event_id, TEXT
  column      :sender, TEXT
  column      :origin_server_ts, :bigint
  column      :content, :blob, default: Sequel.lit("'{}'"), null: false
  column      :prev_content, :blob
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id event_type state_key],
    unique: true,
    name:   :index_matrix_room_state_on_room_id_and_event_type_and_state_key
  index :room_id, name: :index_matrix_room_state_on_room_id
end
