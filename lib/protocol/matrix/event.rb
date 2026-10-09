# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "errors"

module Protocol
  module Matrix
    # Represents a Matrix event, however it arrived — a /sync response, an
    # application service transaction, or a hash you built yourself.
    #
    # Provides typed accessors for all envelope fields plus schema-driven
    # validation using the official Matrix spec YAML schemas.
    #
    #   event = Event.new(raw_hash)
    #   event.type           # => "m.room.message"
    #   event.sender         # => "@alice:example.org"
    #   event.content.body   # => "hello"
    #   event.valid?         # => true
    #   event.valid!         # => true (or raises Protocol::Matrix::Errors::ValidationError)
    #
    class Event
      attr_reader :type,
        :sender,
        :room_id,
        :state_key,
        :content,
        :event_id,
        :origin_server_ts,
        :unsigned,
        :raw

      def initialize(data)
        @raw       = data
        @type      = data["type"]
        @sender    = data["sender"]
        @room_id   = data["room_id"]
        @state_key = data["state_key"]
        @event_id  = data["event_id"]
        @origin_server_ts = data["origin_server_ts"]
        @unsigned  = data["unsigned"]
        @content   = Content.new(data["content"] || {})
      end

      # The JSONSchemer::Schema for this event's type, or nil if unknown.
      def schema = Schema[@type]

      # Validate this event against its schema.
      # Returns true if valid or if no schema exists (lenient).
      def valid? = Schema.valid?(@raw)

      # Validate this event against its schema.
      # Raises Protocol::Matrix::Errors::ValidationError with detailed errors on failure.
      # Returns true if valid or if no schema exists.
      def valid!
        errors = Schema.validate(@raw)

        unless errors.empty?
          raise Protocol::Matrix::Errors::ValidationError.new(
            errors,
            event_type: @type,
            event_id:   @event_id,
          )
        end

        true
      end

      # Content property names defined by the schema for this event type.
      # @return [Array<String>]
      def content_properties = Schema.content_properties(@type)

      # Is this a state event? (has a state_key)
      def state_event? = !@state_key.nil?

      # ── The shape MessageBatch yields ───────────────────────────────────────
      #
      # A batch mixes plaintext and encrypted events, and a consumer should not
      # have to ask which class it is holding before reading #type or #content.
      # So both answer the same three questions, and for a plaintext event the
      # answers are the trivial ones: it was never encrypted, so there is
      # nothing left to decrypt.

      def encrypted? = false
      def decrypted? = true
    end
  end
end

__END__
  describe "Protocol::Matrix::Event" do
    it "parses all event fields" do
      event = Protocol::Matrix::Event.new({
        "type" => "m.room.message",
        "sender" => "@alice:example.com",
        "room_id" => "!abc:example.com",
        "state_key" => "",
        "event_id" => "$evt1",
        "origin_server_ts" => 1234567890,
        "unsigned" => {"age" => 1000},
        "content" => {"msgtype" => "m.text", "body" => "hi"}
      })
      event.type.should == "m.room.message"
      event.sender.should == "@alice:example.com"
      event.room_id.should == "!abc:example.com"
      event.state_key.should == ""
      event.event_id.should == "$evt1"
      event.origin_server_ts.should == 1234567890
      event.unsigned.should == {"age" => 1000}
      event.content.should.be.kind_of Protocol::Matrix::Content
      event.content.body.should == "hi"
    end

    it "defaults content to empty Content when missing" do
      event = Protocol::Matrix::Event.new({"type" => "m.room.message"})
      event.content.should.be.kind_of Protocol::Matrix::Content
      event.content.body.should.be.nil
    end

    it "exposes the raw hash" do
      data = {"type" => "m.room.message", "content" => {"body" => "hi", "msgtype" => "m.text"}}
      event = Protocol::Matrix::Event.new(data)
      event.raw.should.equal data
    end

    it "detects state events" do
      state = Protocol::Matrix::Event.new({"type" => "m.room.member", "state_key" => "@a:b"})
      state.state_event?.should == true

      msg = Protocol::Matrix::Event.new({"type" => "m.room.message"})
      msg.state_event?.should == false
    end

    it "returns the schema for known event types" do
      event = Protocol::Matrix::Event.new({"type" => "m.room.message", "content" => {}})
      event.schema.should.not.be.nil
      event.schema.should.be.kind_of JSONSchemer::Schema
    end

    it "returns nil schema for unknown event types" do
      event = Protocol::Matrix::Event.new({"type" => "m.custom.event", "content" => {}})
      event.schema.should.be.nil
    end

    it "validates a correct event" do
      event = Protocol::Matrix::Event.new({
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text", "body" => "hello"},
        "event_id" => "$abc123",
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1234567890,
        "room_id" => "!room:example.org"
      })
      event.valid?.should == true
      event.valid!.should == true
    end

    it "rejects an invalid event" do
      event = Protocol::Matrix::Event.new({
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text"},
        "event_id" => "$abc123",
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1234567890,
        "room_id" => "!room:example.org"
      })
      event.valid?.should == false
    end

    it "raises ValidationError from valid!" do
      event = Protocol::Matrix::Event.new({
        "type" => "m.room.member",
        "content" => {"membership" => "invalid_state"},
        "state_key" => "@alice:example.org",
        "event_id" => "$abc123",
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1234567890,
        "room_id" => "!room:example.org"
      })
      begin
        event.valid!
        raise "should have raised"
      rescue Protocol::Matrix::Errors::ValidationError => e
        e.message.should.include "m.room.member"
        e.message.should.include "$abc123"
        e.errors.should.not.be.empty
      end
    end

    it "is lenient with unknown event types" do
      event = Protocol::Matrix::Event.new({
        "type" => "com.custom.event",
        "content" => {"anything" => "goes"},
        "event_id" => "$x",
        "sender" => "@a:b"
      })
      event.valid?.should == true
      event.valid!.should == true
    end

    it "returns content properties for known types" do
      event = Protocol::Matrix::Event.new({
        "type" => "m.room.member",
        "content" => {"membership" => "join"}
      })
      props = event.content_properties
      props.should.include "membership"
    end
  end
