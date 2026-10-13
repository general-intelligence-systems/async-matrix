# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class RoomKeyBundle < Sequel::Model(:matrix_room_key_bundles)
      PENDING  = "pending"
      RECEIVED = "received"
      IMPORTED = "imported"
      STATES   = [PENDING, RECEIVED, IMPORTED].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :bundle

      def validate
        super
        validates_presence :room_id
        validates_includes STATES, :state
        validates_unique %i[room_id sender_user_id]
      end

      dataset_module do
        def pending  = where(state: PENDING)
        def received = where(state: RECEIVED)

        def importable = where(state: RECEIVED).exclude(bundle: nil)
      end

      def imported? = state == IMPORTED

      def imported!
        update(state: IMPORTED, bundle: nil)
      end
    end
  end
end

__END__

create_table?(:matrix_room_key_bundles) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :sender_user_id, TEXT
  column      :state, TEXT, default: "pending", null: false
  column      :bundle, :blob
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id sender_user_id],
    unique: true,
    name:   :index_matrix_room_key_bundles_on_room_id_and_sender_user_id
  index :state, name: :index_matrix_room_key_bundles_on_state
end
