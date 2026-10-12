# frozen_string_literal: true

require "json"
require "sequel/model"

module Models
  module Matrix
    # JSONB columns, which in SQLite are a BLOB and SQLite's business.
    #
    # SQLite HAS JSONB -- natively, since 3.44 -- and extralite-bundle vendors
    # its own SQLite, so it is there whatever the system library is. It is not
    # Postgres's jsonb: the column is declared BLOB, written through the
    # `jsonb()` function, and read back as SQLite's internal binary encoding.
    #
    # WHICH IS THE WHOLE PROBLEM THIS MODULE SOLVES. That encoding is a
    # pre-parsed tree, not text, and Ruby cannot parse it -- a bare `SELECT *`
    # hands you an ASCII-8BIT string with no way in. So a model declaring
    # `jsonb :content` gets two things:
    #
    #   * its dataset selects `json(content) AS content`, which asks SQLite to
    #     render the tree back to text on the way out, and
    #   * a serializer that wraps writes in `jsonb(...)` and parses reads.
    #
    # The columns stay in their original positions in the select, so #columns
    # and the physical order still agree.
    #
    # THE POINT OF KEEPING IT BINARY, rather than storing JSON text and parsing
    # it, is that `->` and `->>` read a JSONB tree about twice as fast as they
    # parse text -- and those operators are how the indexed lookups here are
    # written. KeyRequest.for_session's `info ->> 'session_id'` reads the blob
    # directly and never goes near this module.
    #
    # WHAT NOT TO DO: `Sequel.pg_jsonb`. It is Postgres's, it needs the
    # pg_json extension, and the serializer below is what replaced it.
    module JSONB
      # Declare which of this model's BLOB columns hold JSONB.
      def jsonb(*names)
        plugin :serialization

        set_dataset(
          dataset.select(
            *columns.map do |column|
              if names.include?(column)
                Sequel.function(:json, column).as(column)
              else
                column
              end
            end,
          ),
        )

        names.each do |name|
          serialize_attributes([SERIALIZER, DESERIALIZER], name)
        end
      end

      # Out: the Ruby value as a `jsonb('...')` call, which SQLite encodes.
      # Nil stays nil -- a nullable JSONB column means "no document", and
      # `jsonb('null')` is a document containing null, which is a different
      # thing.
      SERIALIZER = lambda do |value|
        if value.nil?
          nil
        else
          Sequel.function(:jsonb, JSON.generate(value))
        end
      end

      # In: the text `json()` rendered, from the select above.
      DESERIALIZER = lambda do |value|
        if value.nil?
          nil
        else
          JSON.parse(value)
        end
      end
    end
  end
end
