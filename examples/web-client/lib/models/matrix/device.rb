# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class Device < Sequel::Model(:matrix_devices)
      UNSET       = "unset"
      VERIFIED    = "verified"
      BLACKLISTED = "blacklisted"
      IGNORED     = "ignored"
      TRUST_STATES = [UNSET, VERIFIED, BLACKLISTED, IGNORED].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :algorithms, :keys, :signatures

      def validate
        super
        validates_presence %i[matrix_user_id device_id]
        validates_includes TRUST_STATES, :trust_state
        validates_unique %i[matrix_user_id device_id]
      end

      dataset_module do
        def of_user(matrix_user_id) = where(matrix_user_id: matrix_user_id)

        def live = where(deleted: false)

        def verified    = where(trust_state: VERIFIED)
        def blacklisted = where(trust_state: BLACKLISTED)

        def sendable = live.exclude(trust_state: [BLACKLISTED, IGNORED])

        def with_identity_key(key) = where(identity_key: key)
      end

      def verified?    = trust_state == VERIFIED
      def blacklisted? = trust_state == BLACKLISTED
      def sendable?    = !deleted && ![BLACKLISTED, IGNORED].include?(trust_state)

      def curve25519 = identity_key
      def ed25519    = fingerprint

      def olm_sessions
        OlmSession.with_peer(identity_key)
      end
    end
  end
end

__END__

create_table?(:matrix_devices) do
  primary_key :id, type: :Bignum, serial: true
  # The Matrix user this device belongs to -- @alice:example.org, not
  # the local account.
  column      :matrix_user_id, TEXT, null: false
  column      :device_id, TEXT, null: false
  # Hoisted out of `keys` because every send looks them up: curve25519
  # to open an Olm session, ed25519 to check a signature.
  column      :identity_key, TEXT
  column      :fingerprint, TEXT
  column      :algorithms, :blob, default: Sequel.lit("'[]'"), null: false
  column      :keys, :blob, default: Sequel.lit("'{}'"), null: false
  column      :signatures, :blob, default: Sequel.lit("'{}'"), null: false
  column      :display_name, TEXT
  # LocalTrust: unset / verified / blacklisted / ignored.
  column      :trust_state, TEXT, default: "unset", null: false
  column      :deleted, :boolean, default: false, null: false
  # Whether we have already told this device why we withheld a key, so
  # we do not tell it again on every message.
  column      :withheld_code_sent, :boolean, default: false, null: false
  column      :last_seen_ts, :bigint
  column      :last_seen_ip, TEXT
  column      :first_seen_at, :bigint
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[matrix_user_id device_id],
    unique: true,
    name:   :index_matrix_devices_on_matrix_user_id_and_device_id
  index :matrix_user_id, name: :index_matrix_devices_on_matrix_user_id
  index :identity_key, name: :index_matrix_devices_on_identity_key
end
