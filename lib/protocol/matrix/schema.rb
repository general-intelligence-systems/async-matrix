# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Protocol
  module Matrix
    # Schema-driven validation for Matrix events using the official matrix-org/matrix-spec
    # YAML schemas and the json_schemer gem.
    #
    # Schemas are loaded lazily from data/matrix-spec/event-schemas/schema/ and cached
    # for the process lifetime. This ensures validation is always up-to-date with the
    # spec -- just re-run `bin/fetch-matrix-schemas` to pull the latest.
    #
    #   # Look up a schema by event type
    #   Protocol::Matrix::Schema["m.room.message"]  # => JSONSchemer::Schema
    #
    #   # Validate an event hash
    #   Protocol::Matrix::Schema.valid?(event_hash)  # => true/false
    #   Protocol::Matrix::Schema.validate(event_hash) # => [errors]
    #
    #   # List all known event types
    #   Protocol::Matrix::Schema.event_types  # => ["m.accepted_terms", "m.call.answer", ...]
    #
    module Schema
      class << self
        # Look up a schema by Matrix event type.
        # @param event_type [String] e.g. "m.room.message"
        # @return [JSONSchemer::Schema, nil]
        def [](event_type)
          Registry.instance[event_type]
        end

        # Look up a variant schema.
        # @param event_type [String] e.g. "m.room.message"
        # @param subtype [String] e.g. "m.text"
        # @return [JSONSchemer::Schema, nil]
        def variant(event_type, subtype)
          Registry.instance.variant(event_type, subtype)
        end

        # Validate an event hash against its schema.
        # @param event_hash [Hash] the raw event data (string keys)
        # @return [Array<Hash>] array of error hashes (empty if valid)
        def validate(event_hash)
          Registry.instance.validate(event_hash)
        end

        # Boolean validation.
        # @param event_hash [Hash] the raw event data (string keys)
        # @return [Boolean]
        def valid?(event_hash)
          Registry.instance.valid?(event_hash)
        end

        # All known base event types.
        # @return [Array<String>] sorted
        def event_types
          Registry.instance.event_types
        end

        # All known variant types as [event_type, subtype] pairs.
        # @return [Array<Array(String, String)>]
        def variant_types
          Registry.instance.variant_types
        end

        # Content properties defined by the schema for a given event type.
        # @return [Array<String>]
        def content_properties(event_type)
          Registry.instance.content_properties(event_type)
        end

        # Parse a raw event hash into a schema-aware Event.
        # @param event_hash [Hash] the raw event data (string keys)
        # @return [Event]
        def parse(event_hash)
          Event.new(event_hash)
        end

        # Total schemas loaded (base + variants).
        # @return [Integer]
        def size
          Registry.instance.size
        end
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::Schema" do
    it "looks up schemas by event type" do
      schema = Protocol::Matrix::Schema["m.room.message"]
      schema.should.not.be.nil
      schema.should.be.kind_of JSONSchemer::Schema
    end

    it "returns nil for unknown event types" do
      Protocol::Matrix::Schema["m.fake.event"].should.be.nil
    end

    it "validates event hashes" do
      valid_event = {
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text", "body" => "hello"},
        "event_id" => "$abc123",
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1234567890,
        "room_id" => "!room:example.org"
      }
      Protocol::Matrix::Schema.valid?(valid_event).should == true
    end

    it "returns errors for invalid events" do
      invalid_event = {
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text"},
        "event_id" => "$abc123",
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1234567890,
        "room_id" => "!room:example.org"
      }
      errors = Protocol::Matrix::Schema.validate(invalid_event)
      errors.should.not.be.empty
    end

    it "lists event types" do
      types = Protocol::Matrix::Schema.event_types
      types.should.be.kind_of Array
      types.should.include "m.room.message"
      types.should.include "m.room.member"
    end

    it "lists variant types" do
      variants = Protocol::Matrix::Schema.variant_types
      variants.should.not.be.empty
    end

    it "looks up variant schemas" do
      schema = Protocol::Matrix::Schema.variant("m.room.message", "m.text")
      schema.should.not.be.nil
    end

    it "returns content properties" do
      props = Protocol::Matrix::Schema.content_properties("m.room.message")
      props.should.include "msgtype"
      props.should.include "body"
    end

    it "reports total schema count" do
      Protocol::Matrix::Schema.size.should.be > 50
    end

    it "parses a raw hash into a schema-aware Event" do
      event = Protocol::Matrix::Schema.parse({
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text", "body" => "hello"},
        "event_id" => "$abc123",
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1234567890,
        "room_id" => "!room:example.org"
      })
      event.should.be.kind_of Protocol::Matrix::Event
      event.type.should == "m.room.message"
      event.content.body.should == "hello"
      event.valid?.should == true
      event.schema.should.not.be.nil
    end
  end
