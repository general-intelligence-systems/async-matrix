# frozen_string_literal: true

# Sequel, from nothing to loaded models, in the one order that works.
#
#   1. the extension, before any connection exists
#   2. the connection, to one session's database
#   3. the tables, read out of the models' own files as TEXT
#   4. the model classes
#
# STEPS 3 AND 4 CANNOT SWAP. `class Room < Sequel::Model(:matrix_rooms)` reads
# that table's schema while the class body is being evaluated, so requiring a
# model before its table exists raises. That is the whole reason the tables are
# read as text rather than by loading the classes that carry them: this file
# opens `lib/models/matrix/room.rb`, takes what is below its `__END__`, and runs
# that -- without Ruby ever parsing the class above the fold.
#
# EVERY TABLE LIVES UNDER ITS OWN MODEL'S `__END__`. `room.rb` is the Room model
# and the matrix_rooms table in one file, in that order, with the table below the
# fold; the same convention the Inertia pages under `app/` use for their TSX.
# Read a model and its table together or not at all.

require "fileutils"

require "extralite"
require "sequel"
require "sequel/model"

# Before the connection, not after: it is the connection pool this changes.
Sequel.extension :fiber_concurrency

# ── One database per session ────────────────────────────────────────────────
#
# This is Fractal's layout and it is not an incidental one. Fractal gives every
# session a directory of its own and opens a fresh set of stores in it, so no
# table anywhere carries a user column -- a store IS one account's, and two
# accounts cannot see each other because they are two files.
#
# So nothing here is scoped by user either. `Room.where(room_id: …)`, not
# `Room.where(user_id: …, room_id: …)`; `Credential.first` is THE credential,
# and `DeviceState.current` is THE device state, because a session has one.
#
# WHICH SESSION IS AN ENVIRONMENT QUESTION, not a per-request one: this connects
# once, at boot, to the session named by MATRIX_SESSION. Fractal keeps its
# equivalent of that choice in GSettings (`sessions` and `current-session`) and
# the passphrase for each store in the Secret Service. Switching sessions here
# means reconnecting, which is a thing to build when there is a second account
# to switch to.
#
# `require "extralite"` above is what registers the scheme -- the adapter ships
# with the gem rather than with Sequel, so Sequel.connect alone would not find
# it.
SESSIONS = File.expand_path(ENV.fetch("MATRIX_SESSIONS", "sessions"), Dir.pwd)
SESSION  = ENV.fetch("MATRIX_SESSION", "default")

FileUtils.mkdir_p(SESSIONS) unless File.directory?(SESSIONS)

DB = Sequel.connect(ENV.fetch("DATABASE_URL", "extralite://#{SESSIONS}/#{SESSION}.db"))

Sequel::Model.db = DB

module Models
  module Matrix
    # The `matrix_*` tables.
    #
    # THE REFERENCE IS FRACTAL, which means it is really matrix-sdk-sqlite:
    # Fractal has no SQL of its own, and persists through the Rust SDK's four
    # stores. Those four, and what of each is here:
    #
    #   state_store        room_info, state_event, member, profile, display_name,
    #                      global_account_data, room_account_data, receipt,
    #                      global_profiles, send_queue_events,
    #                      dependent_send_queue_events, thread_subscriptions,
    #                      kv, kv_blob
    #   crypto_store       session, inbound_group_session,
    #                      outbound_group_session, device, identity,
    #                      tracked_user, olm_hash, key_requests,
    #                      direct_withheld_info, secrets_inbox, room_settings,
    #                      received_room_key_bundle, rooms_pending_key_bundle,
    #                      room_key_backups_fully_downloaded
    #   event_cache_store  linked_chunks, gap_chunks, event_chunks, events,
    #                      threads
    #   media_store        media
    #
    # FOUR DATABASES THERE, ONE HERE. The SDK splits them because two of them
    # are a CACHE -- event_cache_store and media_store live in the cache
    # directory, state and crypto in the data directory, so that clearing a
    # cache cannot destroy a room key. Everything is in one file here, which is
    # the deliberate departure; honouring the split would mean four connections
    # and a Sequel::Model per database for no benefit a web client sees.
    #
    # WHAT IS NOT BORROWED IS THE ENCODING, and this is the big one. Every SDK
    # row is `(hashed key…, data BLOB)` -- keys hashed, values encrypted with a
    # passphrase from the keyring. `room_info` is literally `room_id, state,
    # data`. That is correct for a local client holding somebody's messages on
    # their own disk, and useless here: the Inertia pages select columns, sort on
    # them and filter on them, so what the SDK buries in `data` is hoisted into
    # real columns. Nothing in this schema is opaque.
    #
    # NAMES ARE OURS, NOT THE SDK'S. `matrix_timeline_chunks` is its
    # `linked_chunks` with its `gap_chunks` folded in as a `kind`,
    # `matrix_timeline_entries` is its `event_chunks`, `matrix_devices` is its
    # `device`, `matrix_withheld_keys` is its `direct_withheld_info`. The shape
    # is borrowed; the spelling is matrix_-prefixed and plural throughout.
    #
    # THREE OF ITS TABLES HAVE NO COUNTERPART HERE, deliberately:
    #
    #   lease_locks   a cross-process lock. One Falcon process holds this
    #                 database; there is nothing to lock against.
    #   profile       per-room profile, folded into matrix_room_members, which
    #                 already carries display_name and avatar_url.
    #   room_key_backups_fully_downloaded
    #                 a one-column table, folded into matrix_rooms as a boolean.
    #
    # AND TWO THINGS FRACTAL DOES NOT KEEP IN SQL AT ALL:
    #
    #   matrix_credentials  Fractal's is a Secret Service item per session --
    #                       attributes homeserver, user, device-id, id,
    #                       client-id, with the store passphrase as the secret.
    #                       A web app has no keyring, so it is a table.
    #   the session list    Fractal's GSettings `sessions` and
    #                       `current-session`. Here it is the filenames in
    #                       SESSIONS and the MATRIX_SESSION environment
    #                       variable.
    module Migrations
      MODELS_DIR = File.expand_path("../lib/models/matrix", __dir__)

      # The two types nearly every column is. Spelled out rather than taken from
      # Sequel's shorthands because `String` is varchar(255) and SQLite's TEXT
      # has no length at all, and because a declared type is what gives a SQLite
      # column its affinity -- "text" gets TEXT, where a longhand "character
      # varying" would have got NUMERIC.
      #
      # These resolve from inside the table bodies, which is why they are
      # constants of THIS module: a body is `module_eval`'d here, so its lexical
      # scope for constant lookup is this module and nothing else.
      TEXT      = "text"
      TIMESTAMP = "timestamp"

      # FILE NAMES, NOT CLASSES, and the order the tables are created in --
      # which is also the order the classes are required in afterwards.
      #
      # The order is free. No table declares a foreign key: every reference here
      # is by Matrix id (room_id, event_id, a user's mxid) rather than by row id,
      # because those are the ids the protocol speaks and the ones arriving over
      # /sync. The SDK does the same, and for the same reason.
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
        member_display_name
        media
      ].freeze

      # Idempotent, which is what makes it safe to run on every boot: a table
      # that exists is left exactly as it is.
      def self.create!(db)
        MODELS.each do |model|
          apply(db, model)
        end
      end

      # Run one model's table. `module_eval` rather than `instance_eval` so that
      # TEXT and TIMESTAMP resolve: constant lookup inside an eval'd string
      # follows the cref, which `module_eval` sets to this module.
      #
      # The path and line are passed through so a backtrace points at the model
      # file and the real line number, not at `(eval)`.
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

# And only now the classes, each of which reads its table on the way in.
Models::Matrix::Migrations::MODELS.each do |model|
  require File.join(Models::Matrix::Migrations::MODELS_DIR, model)
end
