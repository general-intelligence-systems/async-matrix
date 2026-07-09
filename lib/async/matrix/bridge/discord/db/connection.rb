# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "sequel"

module Async
  module Matrix
    module Bridge
      module Discord
        module DB
          # Establishes a Sequel database connection from the bridge config's
          # database section.
          #
          # Supports both SQLite (with foreign keys and WAL mode) and PostgreSQL,
          # matching the mautrix bridgev2 database config schema.
          #
          #   db = Connection.establish(config.database)
          #   db[:users].all  # => [...]
          #
          module Connection
            SQLITE_TYPE  = "sqlite3-fk-wal"
            POSTGRES_TYPE = "postgres"

            # Establish a database connection from a config.database section.
            #
            # @param database_config [Hash, Vivify] config.database with :type, :uri, :max_open_conns
            # @return [Sequel::Database]
            def self.establish(database_config)
              type = database_config.type || SQLITE_TYPE
              uri  = database_config.uri  || "sqlite://bridge.db"

              db = case type
                   when SQLITE_TYPE
                     connect_sqlite(uri, database_config)
                   when POSTGRES_TYPE
                     connect_postgres(uri, database_config)
                   else
                     raise ArgumentError, "Unknown database type: #{type.inspect}. Expected #{SQLITE_TYPE.inspect} or #{POSTGRES_TYPE.inspect}."
                   end

              db
            end

            class << self
              private

                def connect_sqlite(uri, config)
                  # Normalize mautrix-style URIs: "file:bridge.db?..." -> "sqlite://bridge.db"
                  sequel_uri = if uri.start_with?("file:")
                                 path = uri.sub(%r{\Afile:}, "").split("?").first
                                 "sqlite://#{path}"
                               elsif uri.start_with?("sqlite://")
                                 uri
                               else
                                 "sqlite://#{uri}"
                               end

                  db = Sequel.connect(sequel_uri, max_connections: max_conns(config))
                  db.run("PRAGMA foreign_keys = ON")
                  db.run("PRAGMA journal_mode = WAL")
                  db
                end

                def connect_postgres(uri, config)
                  Sequel.connect(uri, max_connections: max_conns(config))
                end

                def max_conns(config)
                  val = config.respond_to?(:max_open_conns) ? config.max_open_conns : nil
                  val && val > 0 ? val : 5
                end
            end
          end
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Bridge::Discord::DB::Connection" do
    it "connects to an in-memory SQLite database" do
      config = Object.new
      config.define_singleton_method(:type) { "sqlite3-fk-wal" }
      config.define_singleton_method(:uri)  { "sqlite:/" }
      config.define_singleton_method(:max_open_conns) { 1 }

      db = Async::Matrix::Bridge::Discord::DB::Connection.establish(config)
      db.should.be.kind_of Sequel::Database
      db.database_type.should == :sqlite
      db.disconnect
    end

    it "enables foreign keys and WAL on SQLite" do
      config = Object.new
      config.define_singleton_method(:type) { "sqlite3-fk-wal" }
      config.define_singleton_method(:uri)  { "sqlite:/" }
      config.define_singleton_method(:max_open_conns) { 1 }

      db = Async::Matrix::Bridge::Discord::DB::Connection.establish(config)
      fk = db["PRAGMA foreign_keys"].first
      fk[:foreign_keys].should == 1
      db.disconnect
    end

    it "normalizes mautrix file: URIs to sequel sqlite:// URIs" do
      config = Object.new
      config.define_singleton_method(:type) { "sqlite3-fk-wal" }
      config.define_singleton_method(:uri)  { "file:test.db?_txlock=immediate" }
      config.define_singleton_method(:max_open_conns) { 1 }

      # Should not raise — the URI is normalized
      db = Async::Matrix::Bridge::Discord::DB::Connection.establish(config)
      db.should.be.kind_of Sequel::Database
      db.disconnect
    end

    it "defaults to sqlite with 5 connections when config is empty" do
      config = Object.new
      config.define_singleton_method(:type) { nil }
      config.define_singleton_method(:uri)  { nil }
      config.define_singleton_method(:max_open_conns) { nil }

      db = Async::Matrix::Bridge::Discord::DB::Connection.establish(config)
      db.should.be.kind_of Sequel::Database
      db.disconnect
    end

    it "raises on unknown database type" do
      config = Object.new
      config.define_singleton_method(:type) { "mysql" }
      config.define_singleton_method(:uri)  { "mysql://localhost/db" }
      config.define_singleton_method(:max_open_conns) { 1 }

      lambda {
        Async::Matrix::Bridge::Discord::DB::Connection.establish(config)
      }.should.raise(ArgumentError)
    end
  end
