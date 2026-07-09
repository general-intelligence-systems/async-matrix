# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "sequel"
require "sequel/extensions/migration"

# The Discord bridge's database layer. Requiring this file loads the whole
# subsystem: the Sequel placeholder (schema), the connection helper, and every
# model class, so DB.connect can bind them all.
require_relative "db/schema"
require_relative "db/connection"
require_relative "db/user"
require_relative "db/guild"
require_relative "db/portal"
require_relative "db/puppet"
require_relative "db/message"
require_relative "db/reaction"
require_relative "db/file"

module Async
  module Matrix
    module Bridge
      module Discord
        # Database module for the Discord bridge.
        #
        # Establishes a connection using the bridge config's database section,
        # runs Sequel migrations, and wires up all model classes to the database.
        #
        # Supports both SQLite (with foreign keys + WAL) and PostgreSQL.
        #
        #   db = Async::Matrix::Bridge::Discord::DB.connect(config)
        #   # All models are now ready:
        #   DB::User.create(mxid: "@alice:example.com")
        #   DB::Portal.where(discord_guild_id: "123").all
        #
        module DB
          MIGRATIONS_PATH = File.join(__dir__, "db", "migrations").freeze

          # Connect to the database, run migrations, and bind all models.
          #
          # @param config [Async::Matrix::ApplicationService::Config] the bridge config
          # @return [Sequel::Database]
          def self.connect(config)
            db = Connection.establish(config.database)
            migrate!(db)
            bind_models(db)
            db
          end

          # Run pending migrations.
          #
          # @param db [Sequel::Database]
          def self.migrate!(db)
            Sequel::Migrator.run(db, MIGRATIONS_PATH)
          end

          # Bind all model classes to the given database.
          #
          # @param db [Sequel::Database]
          def self.bind_models(db)
            Async::Matrix::Bridge::Discord::DB::User.dataset        = db[:users]
            Async::Matrix::Bridge::Discord::DB::Guild.dataset       = db[:guilds]
            Async::Matrix::Bridge::Discord::DB::Portal.dataset      = db[:portals]
            Async::Matrix::Bridge::Discord::DB::Puppet.dataset      = db[:puppets]
            Async::Matrix::Bridge::Discord::DB::Message.dataset     = db[:messages]
            Async::Matrix::Bridge::Discord::DB::Reaction.dataset    = db[:reactions]
            Async::Matrix::Bridge::Discord::DB::CachedFile.dataset  = db[:files]
          end
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Bridge::Discord::DB" do
    it "connects, migrates, and binds models from config" do
      database_config = Object.new
      database_config.define_singleton_method(:type) { "sqlite3-fk-wal" }
      database_config.define_singleton_method(:uri)  { "sqlite:/" }
      database_config.define_singleton_method(:max_open_conns) { 1 }

      config = Object.new
      config.define_singleton_method(:database) { database_config }

      db = Async::Matrix::Bridge::Discord::DB.connect(config)
      db.should.be.kind_of Sequel::Database

      # All tables should exist
      db.tables.should.include :users
      db.tables.should.include :guilds
      db.tables.should.include :portals
      db.tables.should.include :puppets
      db.tables.should.include :messages
      db.tables.should.include :reactions
      db.tables.should.include :files

      # Models should be bound and functional
      db[:users].delete
      db[:guilds].delete
      db[:portals].delete
      db[:puppets].delete

      Async::Matrix::Bridge::Discord::DB::User.create(mxid: "@db_int:x")
      Async::Matrix::Bridge::Discord::DB::User["@db_int:x"].should.not.be.nil

      Async::Matrix::Bridge::Discord::DB::Guild.create(discord_id: "g_int")
      Async::Matrix::Bridge::Discord::DB::Guild["g_int"].should.not.be.nil

      Async::Matrix::Bridge::Discord::DB::Portal.create(discord_id: "p_int", receiver: "")
      Async::Matrix::Bridge::Discord::DB::Portal["p_int", ""].should.not.be.nil

      Async::Matrix::Bridge::Discord::DB::Puppet.create(discord_id: "d_int")
      Async::Matrix::Bridge::Discord::DB::Puppet["d_int"].should.not.be.nil

      db.disconnect
    end

    it "exposes MIGRATIONS_PATH" do
      File.directory?(Async::Matrix::Bridge::Discord::DB::MIGRATIONS_PATH).should == true
    end

    it "is idempotent — running migrations twice does not raise" do
      database_config = Object.new
      database_config.define_singleton_method(:type) { "sqlite3-fk-wal" }
      database_config.define_singleton_method(:uri)  { "sqlite:/" }
      database_config.define_singleton_method(:max_open_conns) { 1 }

      config = Object.new
      config.define_singleton_method(:database) { database_config }

      db = Async::Matrix::Bridge::Discord::DB.connect(config)
      lambda { Async::Matrix::Bridge::Discord::DB.migrate!(db) }.should.not.raise
      db.disconnect
    end
  end
