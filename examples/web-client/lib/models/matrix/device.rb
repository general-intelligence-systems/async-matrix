# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # ── Other people's devices ──────────────────────────────────────────────
    #
    # The ten tables could decrypt but not really encrypt. matrix_olm_sessions
    # is keyed by sender_key alone, which is enough to find a session you
    # already have and useless for the question that comes first: who are the
    # devices in this room, what are their keys, and should I send to them?
    # That answer is /keys/query's, and nothing stored it -- so every send had
    # to re-query, and `shared_with` on an outbound session could not be
    # checked against anything.
    #
    # It is also what verification needs. A device with no stored identity key
    # cannot be verified, and a verification that is not persisted is a
    # verification you do again tomorrow.
    class Device < Sequel::Model(:matrix_devices)
      # matrix-sdk-crypto's LocalTrust. `unset` is the default and means only
      # that nobody has decided; it is not a claim either way.
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
        validates_unique %i[user_id matrix_user_id device_id]
      end

      dataset_module do
        def of_user(matrix_user_id) = where(matrix_user_id: matrix_user_id)

        # A deleted device still has rows -- its keys are what verify the
        # signatures on events it sent while it existed -- so every send has to
        # exclude them explicitly.
        def live = where(deleted: false)

        def verified    = where(trust_state: VERIFIED)
        def blacklisted = where(trust_state: BLACKLISTED)

        # Who to encrypt a room key for: live, and not refused.
        def sendable = live.exclude(trust_state: [BLACKLISTED, IGNORED])

        def with_identity_key(key) = where(identity_key: key)
      end

      def verified?    = trust_state == VERIFIED
      def blacklisted? = trust_state == BLACKLISTED
      def sendable?    = !deleted && ![BLACKLISTED, IGNORED].include?(trust_state)

      # The curve25519 an Olm session is opened against, and the ed25519 a
      # signature is checked with. Hoisted into columns, but the full `keys`
      # object stays authoritative -- these are a cache of two of its entries.
      def curve25519 = identity_key
      def ed25519    = fingerprint

      # Our own session with this device, if we have one. Keyed on the identity
      # key, which is all matrix_olm_sessions knows about a peer.
      def olm_sessions
        OlmSession.where(user_id: user_id).with_peer(identity_key)
      end
    end
  end
end

__END__

create_table?(:matrix_devices) do
  primary_key :id, type: :Bignum, serial: true
  column      :user_id, :bigint, null: false
  # The Matrix user this device belongs to -- @alice:example.org, not
  # the local account.
  column      :matrix_user_id, TEXT, null: false
  column      :device_id, TEXT, null: false
  # Hoisted out of `keys` because every send looks them up: curve25519
  # to open an Olm session, ed25519 to check a signature.
  column      :identity_key, TEXT
  column      :fingerprint, TEXT
  column      :algorithms, :blob, default: Sequel.lit("jsonb('[]')"), null: false
  column      :keys, :blob, default: Sequel.lit("jsonb('{}')"), null: false
  column      :signatures, :blob, default: Sequel.lit("jsonb('{}')"), null: false
  column      :display_name, TEXT
  # LocalTrust: unset / verified / blacklisted / ignored.
  column      :trust_state, TEXT, default: "unset", null: false
  column      :deleted, :boolean, default: false, null: false
  # Whether we have already told this device why we withheld a key, so
  # we do not tell it again on every message.
  column      :withheld_code_sent, :boolean, default: false, null: false
  column      :first_seen_at, :bigint
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[user_id matrix_user_id device_id],
    unique: true,
    name:   :index_matrix_devices_on_user_id_and_matrix_user_id_and_device
  index %i[user_id matrix_user_id],
    name: :index_matrix_devices_on_user_id_and_matrix_user_id
  index %i[user_id identity_key], name: :index_matrix_devices_on_user_id_and_identity_key
end
