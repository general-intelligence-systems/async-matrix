# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "schema"

module Async
  module Matrix
    module Bridge
      module Discord
        module DB
          # Maps a Discord user to a Matrix ghost user.
          #
          # The ghost's Matrix ID is derived from the username template in the
          # bridge config (e.g., @discord_123456:example.com). This model
          # tracks the Discord user's profile info for syncing to Matrix.
          #
          #   puppet = Puppet.create(discord_id: "123", username: "alice", name: "Alice")
          #   puppet.is_bot?          # => false
          #   puppet.double_puppet?   # => true  (if custom_mxid is set)
          #
          class Puppet < Sequel::Model
            unrestrict_primary_key

            def validate
              super
              errors.add(:discord_id, "cannot be empty") if discord_id.nil? || discord_id.empty?
            end

            # Is this puppet configured for double puppeting?
            def double_puppet?
              !custom_mxid.nil? && !custom_mxid.empty?
            end
          end
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Bridge::Discord::DB::Puppet" do
    def setup_db
      db = Sequel.sqlite
      Sequel::Migrator.run(db, File.join(__dir__, "migrations"))
      db
    end

    it "creates and retrieves a puppet" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Puppet.dataset = db[:puppets]

      puppet = Async::Matrix::Bridge::Discord::DB::Puppet.create(
        discord_id: "123",
        name: "Alice",
        username: "alice",
        global_name: "Alice Wonderland"
      )
      puppet.discord_id.should == "123"
      puppet.name.should == "Alice"
      puppet.username.should == "alice"
      puppet.global_name.should == "Alice Wonderland"
      db.disconnect
    end

    it "defaults boolean flags to false" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Puppet.dataset = db[:puppets]

      puppet = Async::Matrix::Bridge::Discord::DB::Puppet.create(discord_id: "200")
      puppet.is_bot.should == false
      puppet.is_webhook.should == false
      puppet.contact_info_set.should == false
      db.disconnect
    end

    it "tracks bot and webhook puppets" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Puppet.dataset = db[:puppets]

      bot = Async::Matrix::Bridge::Discord::DB::Puppet.create(discord_id: "300", is_bot: true)
      bot.is_bot.should == true

      webhook = Async::Matrix::Bridge::Discord::DB::Puppet.create(discord_id: "301", is_webhook: true)
      webhook.is_webhook.should == true
      db.disconnect
    end

    it "detects double puppet configuration" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Puppet.dataset = db[:puppets]

      regular = Async::Matrix::Bridge::Discord::DB::Puppet.create(discord_id: "400")
      regular.double_puppet?.should == false

      double = Async::Matrix::Bridge::Discord::DB::Puppet.create(
        discord_id: "401",
        custom_mxid: "@alice:example.com",
        access_token: "syt_token"
      )
      double.double_puppet?.should == true
      double.access_token.should == "syt_token"
      db.disconnect
    end

    it "validates discord_id is present" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Puppet.dataset = db[:puppets]

      puppet = Async::Matrix::Bridge::Discord::DB::Puppet.new(discord_id: "")
      puppet.valid?.should == false
      puppet.errors[:discord_id].should.not.be.empty
      db.disconnect
    end

    it "updates avatar info" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Puppet.dataset = db[:puppets]

      puppet = Async::Matrix::Bridge::Discord::DB::Puppet.create(discord_id: "500")
      puppet.update(avatar_hash: "abc123", avatar_url: "mxc://example.com/abc")
      puppet.refresh
      puppet.avatar_hash.should == "abc123"
      puppet.avatar_url.should == "mxc://example.com/abc"
      db.disconnect
    end
  end
