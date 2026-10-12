# frozen_string_literal: true

require "securerandom"
require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # A user's ONE Matrix device and its MAS tokens.
    #
    # The engine's BaseController owns the OIDC flow that fills this in; this model owns
    # what makes the device durable. Read the migration for why that matters — in
    # short, the device id is a crypto identity, so it must outlive the Rails
    # session that first minted it.
    #
    # Tokens are encrypted at rest: an access token here is a full Matrix login for
    # the user, and unlike an ApiKey it can't be scoped or revoked from our side.
    #
    # PORTED FROM ActiveRecord. The logic is unchanged; what changed is the ORM.
    # Two of those changes have consequences worth knowing:
    #
    #   * `encrypts` (ActiveRecord Encryption) is Sequel's :column_encryption
    #     plugin here, and THE TWO FORMATS ARE NOT COMPATIBLE. A row exported
    #     from the Rails app restores into the identical column -- it is text
    #     either way -- but the ciphertext will not decrypt on this side. The
    #     tokens do not matter (they expire, and the appservice transport has
    #     none), the recovery key does: it has to be re-entered here once.
    #   * there is no uniqueness rule any more, because there is no `user_id` to
    #     be unique over -- the database is one session's and this table has one
    #     row. Fractal keeps the same thing in the Secret Service rather than a
    #     table: one keyring item per session, whose attributes are homeserver,
    #     user, device-id, id and client-id, with the store passphrase as the
    #     secret.
    class Credential < Sequel::Model(:matrix_credentials)
      # Device ids are minted by us and handed to MAS through the MSC2967 `device:`
      # scope, which accepts 10 characters of [A-Za-z0-9_-].
      DEVICE_ID_LENGTH = 10

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      plugin :column_encryption do |enc|
        enc.key 0, ENV.fetch("MATRIX_ENCRYPTION_KEY")

        enc.column :access_token
        enc.column :refresh_token
        # The 4S recovery key (see the migration): cross-signing + key-backup unlock,
        # shared across the user's clients so none of them ever prompt for it.
        enc.column :recovery_key
      end

      def validate
        super
        validates_presence :device_id
        validates_presence :homeserver_url
        validates_presence :matrix_user_id
      end

      # A fresh device id. Only ever called when a user has none yet, or when MAS
      # refused to re-issue the one on file.
      def self.generate_device_id
        SecureRandom.alphanumeric(DEVICE_ID_LENGTH)
      end

      # This session's durable credentials for +homeserver_url+, or nil when they are
      # for a different homeserver (a redeploy pointing at a new one) and must be
      # re-minted. The DEVICE still survives that — callers re-request it — because
      # the row is only rebuilt, never deleted.
      def self.for(homeserver_url)
        record = first
        if record && record.homeserver_url == homeserver_url
          record
        end
      end

      # Is the access token at or past its expiry, allowing +skew_ms+ of slack so a
      # credential is still live by the time the client's first request lands?
      def expired?(skew_ms = 0)
        if expires_at.nil?
          false
        else
          expires_at - skew_ms <= (Time.now.to_f * 1000).to_i
        end
      end

      # Complete enough to hand to a client? A row can exist with a device but no
      # token (the state after a failed refresh) or without the matrix_user_id the
      # column predates. Either way the answer is the same: re-mint, KEEPING the
      # device — which is exactly what makes those states cheap to recover from.
      def usable?
        !access_token.to_s.empty? && !matrix_user_id.to_s.empty?
      end
    end
  end
end

__END__

create_table?(:matrix_credentials) do
  primary_key :id, type: :Bignum, serial: true
  column      :access_token, :text
  column      :created_at, TIMESTAMP, null: false
  column      :device_id, TEXT, null: false
  column      :expires_at, :bigint
  column      :homeserver_url, TEXT, null: false
  column      :matrix_user_id, TEXT
  column      :recovery_key, :text
  column      :refresh_token, :text
  column      :updated_at, TIMESTAMP, null: false


end
