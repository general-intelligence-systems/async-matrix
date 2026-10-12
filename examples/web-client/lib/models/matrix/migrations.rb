# frozen_string_literal: true

require "sequel"

module Models
  module Matrix
    # The `matrix_*` tables: TEN TRANSCRIBED, NINETEEN NEW, and the ten carry
    # columns the Rails app did not have.
    #
    # EVERY TABLE LIVES UNDER ITS OWN MODEL'S `__END__`, and this is the thing
    # that runs them. `lib/models/matrix/rooms.rb` is the Room model and the
    # matrix_rooms table in one file, in that order, with the migration below
    # the fold; the same convention the Inertia pages under `app/` use for their
    # TSX. Read a model and its table together or not at all -- the split is
    # what let schema.rb drift from the classes it describes.
    #
    # THIS DATABASE IS SQLITE, and the Rails app's was Postgres. That is a
    # recent change and it moved the goalposts, so be clear about which half of
    # the old promise still stands.
    #
    # WHAT STILL STANDS: the ten tables keep schema.rb's column NAMES, their
    # physical ORDER, their nullability, their defaults and every index name
    # verbatim -- including Rails' truncated digest names like
    # idx_on_matrix_app_service_id_kind_0aa44c20ab. Additions are appended after
    # the original columns rather than merged into their alphabetical run, and
    # every added column is nullable or defaulted. So the Rails app's rows still
    # FIT: a dump that has never heard of `prev_batch` loads into a table that
    # has one, as long as it is loaded by column name.
    #
    # WHAT NO LONGER STANDS: `pg_dump --data-only | psql` itself. The transfer is
    # now an export and a load -- COPY is not SQLite's, and the types underneath
    # these columns are different ones. The transcription is still worth having
    # for the same reason it was written, which is that a column named the same
    # thing in both places is a column nobody has to map; it is just no longer
    # true that nothing happens on the way across.
    #
    # Types are therefore SQLite's. `text` rather than ActiveRecord's unbounded
    # `character varying`, `timestamp` rather than `timestamp(6) without time
    # zone`, and a jsonb column is a BLOB holding SQLite's own JSONB -- see
    # Models::Matrix::JSONB, which is what makes one readable from Ruby.
    #
    # TWO FOREIGN KEYS FROM THAT SCHEMA ARE ABSENT, and only those two:
    #
    #   add_foreign_key "matrix_*", "users"
    #   add_foreign_key "matrix_events", "things", on_delete: :nullify
    #
    # This database has no `users` or `things` table -- the controller is a
    # single operator behind SyncAuth, not a multi-tenant app. The COLUMNS stay
    # (`user_id` bigint not null, `thing_id` bigint), so exported rows still
    # carry their original ids and still fit; it is only the constraint that
    # cannot be declared against a table that does not exist. The
    # matrix_app_service_namespaces -> matrix_app_services key is here, because
    # both of its tables are.
    #
    # WHY THERE ARE NINETEEN MORE: the Rails app was a relay. It projected
    # /sync into ten tables and pushed them at clients. This app is the client,
    # and a client has to answer what a relay never asked -- what is this room's
    # join rule, what has been read, what is missing from the middle of this
    # timeline, which of Alice's devices do I trust.
    #
    # The reference is matrix-sdk-sqlite's three stores, since that is what the
    # Matrix clients built on matrix-rust-sdk (Fractal, Element X) actually
    # persist -- and, now, the same engine underneath. Where it keys a row and
    # serializes the body into one opaque blob, these tables keep the body as
    # JSONB and hoist out the fields that get queried: the SDK's blob is
    # encrypted at rest and opaque by design, and ours has to be selectable.
    #
    # NAMES ARE OURS, NOT THE SDK'S. `matrix_timeline_chunks` is its
    # `linked_chunks`, `matrix_devices` is its `device`. The shape is borrowed;
    # the spelling follows this schema's own convention (matrix_-prefixed,
    # plural, user_id-scoped).
    module Migrations
      # The two types nearly every column is. Spelled out rather than taken
      # from Sequel's shorthands because `String` is varchar(255) and SQLite's
      # TEXT has no length at all, and because a declared type is what gives a
      # SQLite column its affinity -- "text" gets TEXT, and the longhand
      # "character varying" these used to be would have got NUMERIC.
      #
      # These resolve from inside the migration bodies, which is why they are
      # constants of THIS module: a body is `module_eval`'d here, so its lexical
      # scope for constant lookup is this module and nothing else.
      TEXT      = "text"
      TIMESTAMP = "timestamp"

      # `primary_key :id, type: :Bignum, serial: true` survived the port
      # unchanged, which is worth knowing before anyone tidies it: both of those
      # options are Postgres's, and Sequel's SQLite adapter ignores them and
      # emits `integer PRIMARY KEY AUTOINCREMENT` -- which is the only spelling
      # SQLite accepts, since AUTOINCREMENT requires INTEGER exactly. So does
      # `foreign_key_constraint_name`, which SQLite does honour.

      # FILE NAMES, NOT CLASSES. A migration is read as TEXT out of the model's
      # file, so nothing here loads a model -- which it must not, because
      # `Sequel::Model(:matrix_rooms)` reads the table's schema at class-body
      # time and the table is what we are about to create.
      #
      # app_service BEFORE app_service_namespace, which is the one place this
      # departs from schema.rb's alphabetical order -- the namespace declares
      # its foreign key inline, and Rails gets to list the tables alphabetically
      # only because it adds every add_foreign_key at the END of the file.
      #
      # The nineteen client models follow in schema.rb's order, which is free --
      # none of them declares a foreign key, for the same reason the ten above
      # dropped two: this database has no `users` table to point at.
      MODELS = %w[
        app_service
        app_service_namespace
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
        thread_subscription
      ].freeze

      # Idempotent, in the shape server.rb already uses for its own tables: a
      # table that exists is left exactly as it is, and the columns added to it
      # since are applied on top.
      def self.create!(db)
        MODELS.each do |model|
          apply(db, model)
        end
      end

      # Run one model's migration. `module_eval` rather than `instance_eval` so
      # that TEXT and TIMESTAMP resolve: constant lookup inside an eval'd
      # string follows the cref, which `module_eval` sets to this module.
      #
      # The path and line are passed through so a backtrace points at the
      # model file and the real line number, not at `(eval)`.
      def self.apply(db, model)
        path   = File.expand_path("#{model}.rb", __dir__)
        source = File.read(path)
        head, body = source.split(/^__END__$/, 2)

        unless body
          raise "#{path} declares no migration: expected a create_table? below __END__"
        end

        @db    = db
        @table = nil
        module_eval(body, path, head.count("\n") + 1)
      end

      # The table under migration, remembered so that `added_columns` below the
      # block does not have to name it again.
      def self.create_table?(table, &block)
        @table = table
        @db.create_table?(table, &block)
      end

      # ── Columns added to the ten transcribed tables ──────────────────────────
      #
      # WHY THIS EXISTS AT ALL: create_table? leaves a table that exists exactly
      # as it is, which is the behaviour every migration relies on. It also
      # means that on the database this schema was written to receive -- an
      # import of the Rails app's ten tables -- not one of the columns added to
      # those tables would ever be created. The table already exists, so its
      # create_table? is a no-op, so the new columns are silently absent and the
      # first write that mentions one fails.
      #
      # KEEP IN STEP WITH THE BLOCK ABOVE IT. This duplicates that block's
      # column declarations, which is the price of create_table? being
      # all-or-nothing; a column added in one place and not the other works on a
      # fresh database and fails on an imported one, which is the worse of the
      # two ways round. The two now sit in the same file a few lines apart,
      # which is the whole reason the tables moved under the models.
      #
      # EVERY ADDED COLUMN IS NULLABLE OR DEFAULTED, which is what keeps the
      # import working: pg_dump --data-only writes COPY with an explicit column
      # list, so a column the dump has never heard of is simply filled in.
      # Adding a NOT NULL column without a default here would break the restore
      # this whole convention exists to protect.
      def self.added_columns(*specs)
        if @db.table_exists?(@table)
          existing = @db.schema(@table).map(&:first)

          specs.each do |name, type, options|
            unless existing.include?(name)
              @db.add_column(@table, name, type, **options)
            end
          end
        end
      end

      # Indexes over those columns, for the same reason and with the same
      # caveat.
      #
      # The existing names are read rather than passing `if_not_exists: true`,
      # which Sequel's SQLite adapter accepts and then drops on the floor -- the
      # second run raises "index already exists". Checking is portable anyway.
      def self.added_indexes(*specs)
        if @db.table_exists?(@table)
          existing = @db.indexes(@table).keys

          specs.each do |columns, name|
            unless existing.include?(name)
              @db.add_index(@table, columns, name: name)
            end
          end
        end
      end
    end
  end
end
