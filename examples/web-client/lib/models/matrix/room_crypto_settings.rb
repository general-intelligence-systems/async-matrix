# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # Per-room encryption policy.
    #
    # Distinct from matrix_rooms.encryption, which is the room's own
    # m.room.encryption state event. This is OUR policy for the room: whether
    # to refuse to send to unverified devices, and the rotation thresholds we
    # apply, which DeviceStore#outbound_session takes as its `rotation:`
    # argument.
    class RoomCryptoSettings < Sequel::Model(:matrix_room_crypto_settings)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :room_id
        validates_unique %i[user_id room_id]
      end

      # Our policy for a room, or the defaults. A room with no row is a room
      # nobody has set a policy for, which is not the same as a room whose
      # policy is permissive -- but it behaves the same, so there is no reason
      # to write a row to say so.
      def self.for(user_id:, room_id:)
        first(user_id: user_id, room_id: room_id) ||
          new(user_id: user_id, room_id: room_id)
      end

      def only_allow_trusted_devices? = !!only_allow_trusted_devices

      # What DeviceStore#outbound_session takes as its `rotation:` argument.
      # Nils are left in: the caller's own defaults are the spec's, and a nil
      # here means "no opinion" rather than "rotate never".
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
  column      :user_id, :bigint, null: false
  column      :room_id, TEXT, null: false
  column      :algorithm, TEXT
  column      :only_allow_trusted_devices, :boolean, default: false, null: false
  column      :session_rotation_period_ms, :bigint
  column      :session_rotation_period_messages, :integer
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[user_id room_id],
    unique: true,
    name:   :index_matrix_room_crypto_settings_on_user_id_and_room_id
end
