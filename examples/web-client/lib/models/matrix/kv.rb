# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class KV < Sequel::Model(:matrix_kv)
      SYNC_TOKEN         = "sync_token"
      SUPPORTED_VERSIONS = "supported_versions"
      WELL_KNOWN         = "well_known"
      HOMESERVER_CAPABILITIES = "homeserver_capabilities"
      UTD_HOOK_MANAGER_DATA   = "utd_hook_manager_data"
      ONE_TIME_KEY_ALREADY_UPLOADED = "one_time_key_already_uploaded"
      THREAD_SUBSCRIPTIONS_CATCHUP_TOKENS = "thread_subscriptions_catchup_tokens"

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
