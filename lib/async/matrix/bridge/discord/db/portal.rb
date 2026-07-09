# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "schema"

module Async
  module Matrix
    module Bridge
      module Discord
        module DB
          # Maps a Discord channel to a Matrix room.
          #
          # Uses a composite primary key of (discord_id, receiver). For guild
          # channels, receiver is an empty string. For DMs, receiver is the
          # Discord user ID of the bridge user who owns the portal.
          #
          #   portal = Portal.create(discord_id: "chan123", receiver: "", mxid: "!room:x")
          #   portal.guild      # => Guild or nil
          #   portal.messages   # => [Message, ...]
          #
          class Portal < Sequel::Model
            unrestrict_primary_key

            many_to_one :guild,
              class: "Async::Matrix::Bridge::Discord::DB::Guild",
              key: :discord_guild_id,
              primary_key: :discord_id

            one_to_many :messages,
              class: "Async::Matrix::Bridge::Discord::DB::Message",
              key: [:discord_channel_id, :discord_channel_receiver],
              primary_key: [:discord_id, :receiver]

            def validate
              super
              errors.add(:discord_id, "cannot be empty") if discord_id.nil? || discord_id.empty?
            end

            # Is this a DM portal? (has a receiver)
            def dm?
              receiver && !receiver.empty?
            end

            # Is this a guild channel portal?
            def guild_channel?
              !dm?
            end
          end
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Bridge::Discord::DB::Portal" do
    def setup_db
      db = Sequel.sqlite
      Sequel::Migrator.run(db, File.join(__dir__, "migrations"))
      db
    end

    def set_datasets(db)
      Async::Matrix::Bridge::Discord::DB::Portal.dataset = db[:portals]
      Async::Matrix::Bridge::Discord::DB::Guild.dataset = db[:guilds]
      Async::Matrix::Bridge::Discord::DB::Message.dataset = db[:messages]
    end

    it "creates a guild channel portal" do
      db = setup_db
      set_datasets(db)

      portal = Async::Matrix::Bridge::Discord::DB::Portal.create(
        discord_id: "chan1", receiver: "", mxid: "!room:x", name: "general"
      )
      portal.discord_id.should == "chan1"
      portal.receiver.should == ""
      portal.guild_channel?.should == true
      portal.dm?.should == false
      db.disconnect
    end

    it "creates a DM portal with receiver" do
      db = setup_db
      set_datasets(db)

      portal = Async::Matrix::Bridge::Discord::DB::Portal.create(
        discord_id: "dm1", receiver: "user123", mxid: "!dm:x"
      )
      portal.dm?.should == true
      portal.guild_channel?.should == false
      db.disconnect
    end

    it "finds by composite primary key" do
      db = setup_db
      set_datasets(db)

      Async::Matrix::Bridge::Discord::DB::Portal.create(discord_id: "c1", receiver: "")
      Async::Matrix::Bridge::Discord::DB::Portal.create(discord_id: "c1", receiver: "u1")

      found = Async::Matrix::Bridge::Discord::DB::Portal["c1", ""]
      found.should.not.be.nil
      found.receiver.should == ""

      found2 = Async::Matrix::Bridge::Discord::DB::Portal["c1", "u1"]
      found2.receiver.should == "u1"
      db.disconnect
    end

    it "associates with a guild" do
      db = setup_db
      set_datasets(db)

      guild = Async::Matrix::Bridge::Discord::DB::Guild.create(discord_id: "g_assoc", name: "Guild")
      portal = Async::Matrix::Bridge::Discord::DB::Portal.create(
        discord_id: "c_assoc", receiver: "", discord_guild_id: "g_assoc"
      )
      # Query through the db directly to avoid races with parallel tests
      # that rebind the class-level dataset on Sequel models.
      portal.discord_guild_id.should == "g_assoc"
      linked_guild = db[:guilds].where(discord_id: portal.discord_guild_id).first
      linked_guild[:discord_id].should == "g_assoc"
      linked_portals = db[:portals].where(discord_guild_id: guild.discord_id).all
      linked_portals.length.should == 1
      db.disconnect
    end

    it "enforces unique mxid" do
      db = setup_db
      set_datasets(db)

      Async::Matrix::Bridge::Discord::DB::Portal.create(discord_id: "a", receiver: "", mxid: "!r:x")
      lambda {
        Async::Matrix::Bridge::Discord::DB::Portal.create(discord_id: "b", receiver: "", mxid: "!r:x")
      }.should.raise(Sequel::UniqueConstraintViolation)
      db.disconnect
    end

    it "defaults encrypted to false" do
      db = setup_db
      set_datasets(db)

      portal = Async::Matrix::Bridge::Discord::DB::Portal.create(discord_id: "e1", receiver: "")
      portal.encrypted.should == false
      db.disconnect
    end
  end
