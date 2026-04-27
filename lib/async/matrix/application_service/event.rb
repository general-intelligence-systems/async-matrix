# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"

module Async
  module Matrix
    module ApplicationService
      class Content
        attr_reader :msgtype, :body, :membership

        def initialize(data)
          @msgtype    = data["msgtype"]
          @body       = data["body"]
          @membership = data["membership"]
        end
      end

      class Event
        attr_reader :type, :sender, :room_id, :state_key, :content, :event_id

        def initialize(data)
          @type      = data["type"]
          @sender    = data["sender"]
          @room_id   = data["room_id"]
          @state_key = data["state_key"]
          @event_id  = data["event_id"]
          @content   = Content.new(data["content"] || {})
        end
      end
    end
  end
end

test do
  describe "Async::Matrix::ApplicationService::Content" do
    it "parses msgtype, body, and membership" do
      content = Async::Matrix::ApplicationService::Content.new({
        "msgtype" => "m.text",
        "body" => "hello",
        "membership" => "join"
      })
      content.msgtype.should == "m.text"
      content.body.should == "hello"
      content.membership.should == "join"
    end

    it "handles missing fields gracefully" do
      content = Async::Matrix::ApplicationService::Content.new({})
      content.msgtype.should.be.nil
      content.body.should.be.nil
      content.membership.should.be.nil
    end
  end

  describe "Async::Matrix::ApplicationService::Event" do
    it "parses all event fields" do
      event = Async::Matrix::ApplicationService::Event.new({
        "type" => "m.room.message",
        "sender" => "@alice:example.com",
        "room_id" => "!abc:example.com",
        "state_key" => "",
        "event_id" => "$evt1",
        "content" => {"msgtype" => "m.text", "body" => "hi"}
      })
      event.type.should == "m.room.message"
      event.sender.should == "@alice:example.com"
      event.room_id.should == "!abc:example.com"
      event.state_key.should == ""
      event.event_id.should == "$evt1"
      event.content.should.be.kind_of Async::Matrix::ApplicationService::Content
      event.content.body.should == "hi"
    end

    it "defaults content to empty Content when missing" do
      event = Async::Matrix::ApplicationService::Event.new({"type" => "m.room.message"})
      event.content.should.be.kind_of Async::Matrix::ApplicationService::Content
      event.content.body.should.be.nil
    end
  end
end
