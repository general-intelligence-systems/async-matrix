# frozen_string_literal: true


require "fileutils"

require "extralite"
require "sequel"
require "sequel/model"

Sequel.extension :fiber_concurrency

SESSIONS = File.expand_path(ENV.fetch("MATRIX_SESSIONS", "sessions"), Dir.pwd)
SESSION  = ENV.fetch("MATRIX_SESSION", "default")

unless File.directory?(SESSIONS)
  FileUtils.mkdir_p(SESSIONS)
end

DB = Sequel.connect(ENV.fetch("DATABASE_URL", "extralite://#{SESSIONS}/#{SESSION}.db"))

Sequel::Model.db = DB

module Models
  module Matrix
    module Migrations
      MODELS_DIR = File.expand_path("../lib/models/matrix", __dir__)

      TEXT      = "text"
      TIMESTAMP = "timestamp"

      MODELS = %w[
        kv
        credential
        device_state
        event
        megolm_inbound_session
        megolm_outbound_session
        olm_session
        room_member
        room
        room_state
        account_data
        receipt
        timeline_chunk
        timeline_entry
        thread_summary
        thread_subscription
        device
        user_identity
        tracked_user
        send_queue
        send_queue_dependent
        olm_hash
        key_request
        room_crypto_settings
        withheld_key
        room_key_bundle
        secrets_inbox
        global_profile
        verification_flow
        member_display_name
        media
      ].freeze

      def self.create!(db)
        MODELS.each do |model|
          apply(db, model)
        end
      end

      def self.apply(db, model)
        path   = File.join(MODELS_DIR, "#{model}.rb")
        source = File.read(path)
        head, body = source.split(/^__END__$/, 2)

        unless body
          raise "#{path} declares no table: expected a create_table? below __END__"
        end

        @db = db
        module_eval(body, path, head.count("\n") + 1)
      end

      def self.create_table?(table, &block)
        @db.create_table?(table, &block)
      end
    end
  end
end

Models::Matrix::Migrations.create!(DB)

Models::Matrix::Migrations::MODELS.each do |model|
  require File.join(Models::Matrix::Migrations::MODELS_DIR, model)
end
