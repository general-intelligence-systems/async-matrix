# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "schema"

module Async
  module Matrix
    module Bridge
      module Discord
        module DB
          # Maps a Discord guild (server) to a Matrix Space room.
          #
          # Bridging modes control how aggressively the bridge creates portals:
          #   BRIDGE_NOTHING         = 0  — never bridge
          #   BRIDGE_IF_PORTAL_EXISTS = 1  — only bridge existing portals
          #   BRIDGE_CREATE_ON_MESSAGE = 2 — create portals on first message
          #   BRIDGE_EVERYTHING      = 3  — proactively create all portals
          #
          #   guild = Guild.create(discord_id: "999", name: "My Server", bridging_mode: 3)
          #   guild.portals  # => [Portal, ...]
          #
          class Guild < Sequel::Model
            unrestrict_primary_key

            BRIDGE_NOTHING           = 0
            BRIDGE_IF_PORTAL_EXISTS  = 1
            BRIDGE_CREATE_ON_MESSAGE = 2
            BRIDGE_EVERYTHING        = 3

            one_to_many :portals,
              class: "Async::Matrix::Bridge::Discord::DB::Portal",
              key: :discord_guild_id,
              primary_key: :discord_id

            def validate
              super
              errors.add(:discord_id, "cannot be empty") if discord_id.nil? || discord_id.empty?
            end

            def bridge_nothing?
              bridging_mode == BRIDGE_NOTHING
            end

            def bridge_everything?
              bridging_mode == BRIDGE_EVERYTHING
            end
          end
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Bridge::Discord::DB::Guild" do
    def setup_db
      db = Sequel.sqlite
      Sequel::Migrator.run(db, File.join(__dir__, "migrations"))
      db
    end

    it "creates and retrieves a guild" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Guild.dataset = db[:guilds]

      guild = Async::Matrix::Bridge::Discord::DB::Guild.create(
        discord_id: "999",
        name: "Test Guild",
        mxid: "!space:example.com"
      )
      guild.discord_id.should == "999"
      guild.name.should == "Test Guild"
      guild.mxid.should == "!space:example.com"
      db.disconnect
    end

    it "defaults bridging_mode to 0 (nothing)" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Guild.dataset = db[:guilds]

      guild = Async::Matrix::Bridge::Discord::DB::Guild.create(discord_id: "100")
      guild.bridging_mode.should == 0
      guild.bridge_nothing?.should == true
      guild.bridge_everything?.should == false
      db.disconnect
    end

    it "supports all bridging modes" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Guild.dataset = db[:guilds]

      guild = Async::Matrix::Bridge::Discord::DB::Guild.create(discord_id: "200", bridging_mode: 3)
      guild.bridge_everything?.should == true
      guild.bridge_nothing?.should == false
      db.disconnect
    end

    it "validates discord_id is present" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Guild.dataset = db[:guilds]

      guild = Async::Matrix::Bridge::Discord::DB::Guild.new(discord_id: "")
      guild.valid?.should == false
      guild.errors[:discord_id].should.not.be.empty
      db.disconnect
    end

    it "enforces unique mxid" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Guild.dataset = db[:guilds]

      Async::Matrix::Bridge::Discord::DB::Guild.create(discord_id: "300", mxid: "!a:x")
      lambda {
        Async::Matrix::Bridge::Discord::DB::Guild.create(discord_id: "301", mxid: "!a:x")
      }.should.raise(Sequel::UniqueConstraintViolation)
      db.disconnect
    end
  end
