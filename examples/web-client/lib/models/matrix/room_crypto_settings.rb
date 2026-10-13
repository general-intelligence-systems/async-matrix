# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class RoomCryptoSettings < Sequel::Model(:matrix_room_crypto_settings)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :room_id
        validates_unique :room_id
      end

      def self.for(room_id:)
        first(room_id: room_id) ||
          new(room_id: room_id)
      end

      def only_allow_trusted_devices? = !!only_allow_trusted_devices

      def rotation
        {
          period_ms:       session_rotation_period_ms,
          period_messages: session_rotation_period_messages,
        }.compact
      end
    end
  end
end

__END__

create_table?(:matrix_room_crypto_settings) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :algorithm, TEXT
  column      :only_allow_trusted_devices, :boolean, default: false, null: false
  column      :session_rotation_period_ms, :bigint
  column      :session_rotation_period_messages, :integer
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :room_id, unique: true, name: :index_matrix_room_crypto_settings_on_room_id
end
