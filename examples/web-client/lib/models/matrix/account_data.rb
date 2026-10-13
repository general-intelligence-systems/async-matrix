# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class AccountData < Sequel::Model(:matrix_account_data)
      TAG           = "m.tag"
      DIRECT        = "m.direct"
      FULLY_READ    = "m.fully_read"
      IGNORED_USERS = "m.ignored_user_list"
      PUSH_RULES    = "m.push_rules"
      MARKED_UNREAD = "m.marked_unread"

      GLOBAL = ""

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :content

      def validate
        super
        validates_presence :event_type
        validates_unique %i[room_id event_type]
      end

      dataset_module do
        def global          = where(room_id: GLOBAL)
        def in_room(room_id) = where(room_id: room_id)
        def of_type(type)   = where(event_type: type)
      end

      def global? = room_id == GLOBAL

      def self.content_for(event_type:, room_id: GLOBAL)
        row = first(room_id: room_id, event_type: event_type) ||
          first(room_id: GLOBAL, event_type: event_type)
        row&.content
      end
    end
  end
end

__END__

create_table?(:matrix_account_data) do
  primary_key :id, type: :Bignum, serial: true
  # "" for global account data, for the same uniqueness reason as
  # room_state's state_key.
  column      :room_id, TEXT, default: "", null: false
  column      :event_type, TEXT, null: false
  column      :content, :blob, default: Sequel.lit("'{}'"), null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id event_type],
    unique: true,
    name:   :index_matrix_account_data_on_room_id_and_event_type
end
