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
          # Maps a Discord reaction to a Matrix reaction event.
          #
          # Uniquely identified by (discord_message_id, discord_sender,
          # discord_emoji_name) — one reaction per emoji per user per message.
          #
          #   reaction = Reaction.create(
          #     discord_message_id: "msg1", discord_sender: "user1",
          #     discord_emoji_name: "\u{1f44d}", mxid: "$react1",
          #     discord_channel_id: "ch1"
          #   )
          #
          class Reaction < Sequel::Model
            def validate
              super
              errors.add(:discord_message_id, "cannot be empty") if discord_message_id.nil? || discord_message_id.empty?
              errors.add(:discord_sender, "cannot be empty") if discord_sender.nil? || discord_sender.empty?
              errors.add(:discord_emoji_name, "cannot be empty") if discord_emoji_name.nil? || discord_emoji_name.empty?
              errors.add(:mxid, "cannot be empty") if mxid.nil? || mxid.empty?
            end

            # Find all reactions on a Discord message.
            def self.by_discord_message(message_id, channel_id, receiver = "")
              where(
                discord_message_id: message_id,
                discord_channel_id: channel_id,
                discord_channel_receiver: receiver
              ).all
            end

            # Find a specific reaction by its Matrix event ID.
            def self.by_mxid(mxid)
              first(mxid: mxid)
            end

            # Find a specific reaction by Discord compound key.
            def self.by_discord_key(message_id:, sender:, emoji_name:)
              first(
                discord_message_id: message_id,
                discord_sender: sender,
                discord_emoji_name: emoji_name
              )
            end
          end
        end
      end
    end
  end
end

test do
  describe "Async::Matrix::Bridge::Discord::DB::Reaction" do
    def setup_db
      db = Sequel.sqlite
      Sequel::Migrator.run(db, File.join(__dir__, "migrations"))
      db
    end

    it "creates and retrieves a reaction" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Reaction.dataset = db[:reactions]

      reaction = Async::Matrix::Bridge::Discord::DB::Reaction.create(
        discord_message_id: "msg1",
        discord_sender: "user1",
        discord_emoji_name: "\u{1f44d}",
        mxid: "$react1",
        discord_channel_id: "ch1"
      )
      reaction.discord_emoji_name.should == "\u{1f44d}"
      reaction.mxid.should == "$react1"
      db.disconnect
    end

    it "finds reactions by discord message" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Reaction.dataset = db[:reactions]

      Async::Matrix::Bridge::Discord::DB::Reaction.create(
        discord_message_id: "msg2", discord_sender: "u1",
        discord_emoji_name: "\u{1f44d}", mxid: "$r1", discord_channel_id: "ch1"
      )
      Async::Matrix::Bridge::Discord::DB::Reaction.create(
        discord_message_id: "msg2", discord_sender: "u2",
        discord_emoji_name: "\u{2764}", mxid: "$r2", discord_channel_id: "ch1"
      )

      reactions = Async::Matrix::Bridge::Discord::DB::Reaction.by_discord_message("msg2", "ch1")
      reactions.length.should == 2
      db.disconnect
    end

    it "finds by Discord compound key" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Reaction.dataset = db[:reactions]

      Async::Matrix::Bridge::Discord::DB::Reaction.create(
        discord_message_id: "msg3", discord_sender: "u1",
        discord_emoji_name: "custom_emoji", mxid: "$r3", discord_channel_id: "ch1"
      )

      found = Async::Matrix::Bridge::Discord::DB::Reaction.by_discord_key(
        message_id: "msg3", sender: "u1", emoji_name: "custom_emoji"
      )
      found.should.not.be.nil
      found.mxid.should == "$r3"
      db.disconnect
    end

    it "finds by Matrix event ID" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Reaction.dataset = db[:reactions]

      Async::Matrix::Bridge::Discord::DB::Reaction.create(
        discord_message_id: "msg4", discord_sender: "u1",
        discord_emoji_name: "x", mxid: "$find_react", discord_channel_id: "ch1"
      )

      found = Async::Matrix::Bridge::Discord::DB::Reaction.by_mxid("$find_react")
      found.discord_message_id.should == "msg4"
      db.disconnect
    end

    it "enforces unique reaction per user per emoji per message" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Reaction.dataset = db[:reactions]

      Async::Matrix::Bridge::Discord::DB::Reaction.create(
        discord_message_id: "msg5", discord_sender: "u1",
        discord_emoji_name: "x", mxid: "$r5", discord_channel_id: "ch1"
      )
      lambda {
        Async::Matrix::Bridge::Discord::DB::Reaction.create(
          discord_message_id: "msg5", discord_sender: "u1",
          discord_emoji_name: "x", mxid: "$r6", discord_channel_id: "ch1"
        )
      }.should.raise(Sequel::UniqueConstraintViolation)
      db.disconnect
    end

    it "validates required fields" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::Reaction.dataset = db[:reactions]

      r = Async::Matrix::Bridge::Discord::DB::Reaction.new(
        discord_message_id: "", discord_sender: "",
        discord_emoji_name: "", mxid: ""
      )
      r.valid?.should == false
      r.errors[:discord_message_id].should.not.be.empty
      r.errors[:mxid].should.not.be.empty
      db.disconnect
    end
  end
end
