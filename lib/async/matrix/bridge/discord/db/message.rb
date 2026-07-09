# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "schema"

module Async
  module Matrix
    module Bridge
      module Discord
        module DB
          # Maps a Discord message to one or more Matrix events.
          #
          # A single Discord message may produce multiple Matrix events (one per
          # attachment), distinguished by discord_attachment_id. The composite
          # unique index on (discord_id, discord_attachment_id, discord_channel_id,
          # discord_channel_receiver) ensures no duplicates.
          #
          #   msg = Message.create(
          #     discord_id: "msg1", discord_channel_id: "ch1",
          #     discord_sender: "user1", mxid: "$evt1", timestamp: 1234567890
          #   )
          #   msg.portal  # => Portal
          #
          class Message < Sequel::Model
            many_to_one :portal,
              class: "Async::Matrix::Bridge::Discord::DB::Portal",
              key: [:discord_channel_id, :discord_channel_receiver],
              primary_key: [:discord_id, :receiver]

            def validate
              super
              errors.add(:discord_id, "cannot be empty") if discord_id.nil? || discord_id.empty?
              errors.add(:mxid, "cannot be empty") if mxid.nil? || mxid.empty?
              errors.add(:discord_sender, "cannot be empty") if discord_sender.nil? || discord_sender.empty?
            end

            # Find all parts of a Discord message (text + attachments).
            def self.by_discord_id(discord_id, channel_id, receiver = "")
              where(
                discord_id: discord_id,
                discord_channel_id: channel_id,
                discord_channel_receiver: receiver
              ).order(:discord_attachment_id).all
            end

            # Find a message by its Matrix event ID.
            def self.by_mxid(mxid)
              first(mxid: mxid)
            end
          end
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Bridge::Discord::DB::Message" do
    def setup_db
      db = Sequel.sqlite
      Sequel::Migrator.run(db, File.join(__dir__, "migrations"))
      db
    end

    def set_datasets(db)
      Async::Matrix::Bridge::Discord::DB::Message.dataset = db[:messages]
      Async::Matrix::Bridge::Discord::DB::Portal.dataset = db[:portals]
    end

    it "creates and retrieves a message" do
      db = setup_db
      set_datasets(db)

      msg = Async::Matrix::Bridge::Discord::DB::Message.create(
        discord_id: "msg1",
        discord_channel_id: "ch1",
        discord_sender: "user1",
        mxid: "$evt1",
        timestamp: 1234567890
      )
      msg.discord_id.should == "msg1"
      msg.mxid.should == "$evt1"
      msg.discord_attachment_id.should == ""
      db.disconnect
    end

    it "supports multi-part messages with attachments" do
      db = setup_db
      set_datasets(db)

      Async::Matrix::Bridge::Discord::DB::Message.create(
        discord_id: "msg2", discord_attachment_id: "",
        discord_channel_id: "ch1", discord_sender: "u1",
        mxid: "$text", timestamp: 100
      )
      Async::Matrix::Bridge::Discord::DB::Message.create(
        discord_id: "msg2", discord_attachment_id: "att1",
        discord_channel_id: "ch1", discord_sender: "u1",
        mxid: "$img1", timestamp: 100
      )
      Async::Matrix::Bridge::Discord::DB::Message.create(
        discord_id: "msg2", discord_attachment_id: "att2",
        discord_channel_id: "ch1", discord_sender: "u1",
        mxid: "$img2", timestamp: 100
      )

      parts = Async::Matrix::Bridge::Discord::DB::Message.by_discord_id("msg2", "ch1")
      parts.length.should == 3
      parts.map(&:mxid).should == ["$text", "$img1", "$img2"]
      db.disconnect
    end

    it "finds by Matrix event ID" do
      db = setup_db
      set_datasets(db)

      Async::Matrix::Bridge::Discord::DB::Message.create(
        discord_id: "msg3", discord_channel_id: "ch1",
        discord_sender: "u1", mxid: "$find_me", timestamp: 200
      )

      found = Async::Matrix::Bridge::Discord::DB::Message.by_mxid("$find_me")
      found.should.not.be.nil
      found.discord_id.should == "msg3"
      db.disconnect
    end

    it "enforces unique composite key" do
      db = setup_db
      set_datasets(db)

      Async::Matrix::Bridge::Discord::DB::Message.create(
        discord_id: "msg4", discord_attachment_id: "",
        discord_channel_id: "ch1", discord_channel_receiver: "",
        discord_sender: "u1", mxid: "$a", timestamp: 300
      )
      lambda {
        Async::Matrix::Bridge::Discord::DB::Message.create(
          discord_id: "msg4", discord_attachment_id: "",
          discord_channel_id: "ch1", discord_channel_receiver: "",
          discord_sender: "u1", mxid: "$b", timestamp: 300
        )
      }.should.raise(Sequel::UniqueConstraintViolation)
      db.disconnect
    end

    it "validates required fields" do
      db = setup_db
      set_datasets(db)

      msg = Async::Matrix::Bridge::Discord::DB::Message.new(discord_id: "", mxid: "", discord_sender: "")
      msg.valid?.should == false
      msg.errors[:discord_id].should.not.be.empty
      msg.errors[:mxid].should.not.be.empty
      msg.errors[:discord_sender].should.not.be.empty
      db.disconnect
    end
  end
