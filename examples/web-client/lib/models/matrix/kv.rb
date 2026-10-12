# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # The store's own key/value shelf: the handful of things a client has to
    # remember that are not a room, an event or a key.
    #
    # matrix-sdk-sqlite spells this `kv_blob` in the state store and `kv` in the
    # other three, and the SDK reaches it through one enum -- StateStoreDataKey
    # -- whose variants are the constants below. That enum is the whole
    # inventory, so this table has a known set of keys rather than being a
    # free-for-all, and the constants are here so a typo is a NameError instead
    # of a silently absent row.
    #
    # THE SYNC TOKEN IS THE IMPORTANT ONE. It is the cursor /sync resumes from,
    # and losing it means a client that re-downloads the world. DeviceState
    # carries a `sync_token` column as well, which predates this table; that one
    # is the server device's and this one is the store's.
    #
    # COMPOSER DRAFTS are the other entry worth knowing about: an unsent message
    # per room, and per thread within a room, which is what lets a draft survive
    # navigating away. Nothing else in this schema would hold one.
    class KV < Sequel::Model(:matrix_kv)
      SYNC_TOKEN         = "sync_token"
      SUPPORTED_VERSIONS = "supported_versions"
      WELL_KNOWN         = "well_known"
      HOMESERVER_CAPABILITIES = "homeserver_capabilities"
      UTD_HOOK_MANAGER_DATA   = "utd_hook_manager_data"
      ONE_TIME_KEY_ALREADY_UPLOADED = "one_time_key_already_uploaded"
      THREAD_SUBSCRIPTIONS_CATCHUP_TOKENS = "thread_subscriptions_catchup_tokens"

      # These take a subject, joined with ":" exactly as the SDK joins them --
      # "composer_draft:!room:example.org:$threadroot".
      FILTER                = "filter"
      USER_AVATAR_URL       = "user_avatar_url"
      RECENTLY_VISITED_ROOMS = "recently_visited_rooms"
      COMPOSER_DRAFT        = "composer_draft"
      SEEN_KNOCK_REQUESTS   = "seen_knock_requests"
      PRESENCE              = "presence"

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :value

      def validate
        super
        validates_presence :key
        validates_unique :key
      end

      # A key with its subject. The SDK builds the same strings by formatting
      # the enum's payload in, which is why this is a join and not a nested
      # table.
      def self.key_for(name, *subject)
        [name, *subject].join(":")
      end

      def self.[](name, *subject)
        first(key: key_for(name, *subject))&.value
      end

      def self.[]=(name, value)
        set!(name, value)
      end

      def self.set!(name, value, *subject)
        key = key_for(name, *subject)
        row = first(key: key) || new(key: key)
        row.set(value: value)
        row.save
      end

      def self.unset!(name, *subject)
        where(key: key_for(name, *subject)).delete
      end

      # The sync cursor, named because every caller wants it and nobody should
      # be spelling the key.
      def self.sync_token = self[SYNC_TOKEN]

      def self.sync_token=(token)
        set!(SYNC_TOKEN, token)
      end

      def self.composer_draft(room_id, thread_root = nil)
        self[COMPOSER_DRAFT, *[room_id, thread_root].compact]
      end

      def self.set_composer_draft!(room_id, draft, thread_root: nil)
        set!(COMPOSER_DRAFT, draft, *[room_id, thread_root].compact)
      end
    end
  end
end

__END__

create_table?(:matrix_kv) do
  primary_key :id, type: :Bignum, serial: true
  # One of the names in the class above, optionally with its subject joined on
  # after a ":".
  column      :key, TEXT, null: false
  # JSONB, so that a token (a string), a capability set (an object) and a draft
  # (an object) all fit one column.
  column      :value, :blob
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :key, unique: true, name: :index_matrix_kv_on_key
end
