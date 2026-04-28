# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"

module Async
  module Matrix
    module Bridge
      module Discord
        module DB
          # Maps a Matrix user to their Discord identity and session state.
          #
          #   user = User.create(mxid: "@alice:example.com", discord_id: "123456789")
          #   user.discord_id     # => "123456789"
          #   user.space_room     # => "!space:example.com"
          #   user.portals        # => [Portal, ...]
          #
          class User < Sequel::Model
            unrestrict_primary_key

            one_to_many :portals,
              class: "Async::Matrix::Bridge::Discord::DB::Portal",
              key: :receiver,
              primary_key: :discord_id

            def validate
              super
              errors.add(:mxid, "cannot be empty") if mxid.nil? || mxid.empty?
            end
          end
        end
      end
    end
  end
end

test do
  describe "Async::Matrix::Bridge::Discord::DB::User" do
    def setup_db
      db = Sequel.sqlite
      Sequel::Migrator.run(db, File.join(__dir__, "migrations"))
      db
    end

    it "creates and retrieves a user by mxid" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::User.dataset = db[:users]

      user = Async::Matrix::Bridge::Discord::DB::User.create(
        mxid: "@alice:example.com",
        discord_id: "123456789"
      )
      user.mxid.should == "@alice:example.com"
      user.discord_id.should == "123456789"

      found = Async::Matrix::Bridge::Discord::DB::User["@alice:example.com"]
      found.discord_id.should == "123456789"
      db.disconnect
    end

    it "stores optional session fields" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::User.dataset = db[:users]

      user = Async::Matrix::Bridge::Discord::DB::User.create(
        mxid: "@bob:example.com",
        discord_token: "secret_token",
        management_room: "!mgmt:example.com",
        space_room: "!space:example.com",
        dm_space_room: "!dm:example.com"
      )
      user.discord_token.should == "secret_token"
      user.management_room.should == "!mgmt:example.com"
      user.space_room.should == "!space:example.com"
      user.dm_space_room.should == "!dm:example.com"
      db.disconnect
    end

    it "enforces unique discord_id" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::User.dataset = db[:users]

      Async::Matrix::Bridge::Discord::DB::User.create(mxid: "@a:x", discord_id: "111")
      lambda {
        Async::Matrix::Bridge::Discord::DB::User.create(mxid: "@b:x", discord_id: "111")
      }.should.raise(Sequel::UniqueConstraintViolation)
      db.disconnect
    end

    it "validates mxid is present" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::User.dataset = db[:users]

      user = Async::Matrix::Bridge::Discord::DB::User.new(mxid: "")
      user.valid?.should == false
      user.errors[:mxid].should.not.be.empty
      db.disconnect
    end

    it "updates discord token" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::User.dataset = db[:users]

      user = Async::Matrix::Bridge::Discord::DB::User.create(mxid: "@c:x")
      user.update(discord_token: "new_token")
      user.refresh
      user.discord_token.should == "new_token"
      db.disconnect
    end
  end
end
