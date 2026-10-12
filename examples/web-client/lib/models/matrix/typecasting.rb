# frozen_string_literal: true

require "sequel/model"

module Models
  module Matrix
    # Booleans and timestamps, which SQLite does not have.
    #
    # READ THIS BEFORE WRITING A PREDICATE. SQLite stores a boolean as 0 or 1
    # and a timestamp as a string, and extralite's Sequel adapter does no
    # conversion on the way out -- its #fetch_rows hands you what SQLite held,
    # because SQLite's C API does not reliably report a result column's declared
    # type and the adapter does not guess.
    #
    # SO `redacted` ARRIVES AS 0, AND `!!0` IS TRUE IN RUBY. That is not a
    # hypothetical: Event#media_event? is written as `redacted? || ...` over
    # `!!redacted`, and under Postgres it worked. Every boolean predicate in
    # these models would have inverted, silently, on the port -- a redacted
    # message reported as media, a live device reported as deleted, an unwedged
    # send reported as wedged.
    #
    # The fix is Sequel's own typecast_on_load, which exists for exactly this
    # class of adapter: it calls each listed column's setter on load, and a
    # setter typecasts. The columns are derived from the table rather than
    # listed by hand, so a boolean added to a migration is covered without
    # anyone remembering to come back here.
    #
    # THIS ONLY COVERS MODEL LOADS. A bare dataset -- `DB[:matrix_rooms].first`
    # -- still returns 0 and a string, so read through the model, or compare
    # against 0 and 1 deliberately.
    #
    # ── And defaults, which is the same bargain ─────────────────────────────
    #
    # defaults_setter is here for the same reason: the table is the source of
    # truth, and the model has to agree with it BEFORE the insert, not after.
    #
    # A column default is applied by the database, so a new object has nil where
    # the table says "unset" -- and validation runs first. Device's
    # `validates_includes TRUST_STATES, :trust_state` therefore rejected every
    # device nobody had made a trust decision about, which is all of them:
    # `trust_state` defaults to "unset" in the table and was nil in the object.
    # Same for Receipt's "m.read" and RoomKeyBundle's "pending".
    #
    # The plugin reads those defaults off the schema and fills them in on #new,
    # so a validation sees what the row is actually going to contain. A JSONB
    # column's default comes back as the STRING "{}" rather than an empty Hash,
    # which is harmless -- JSONB's serializer is what runs on the way out, and
    # it is given a value it will encode faithfully either way.
    module Typecasting
      # Sequel's normalized types, not SQLite's declared ones. A jsonb column is
      # a blob and is absent from this list on purpose: JSONB owns those, and
      # running a setter over one would re-encode what it just decoded.
      TYPES = %i[boolean date datetime time].freeze

      def self.extended(model)
        columns = model.db.schema(model.table_name).filter_map do |column, info|
          if TYPES.include?(info[:type])
            column
          end
        end

        model.plugin :typecast_on_load, *columns
        model.plugin :defaults_setter
      end
    end
  end
end
