# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"

module Async
	module Matrix
		module ApplicationService
			# Wraps the content object of a Matrix event, providing typed access to
			# schema-defined properties via method_missing.
			#
			# Common fields like `msgtype`, `body`, and `membership` have dedicated
			# accessors for convenience. Any other field defined in the event's schema
			# (or present in the raw hash) is accessible as a method call:
			#
			#   content.msgtype      # => "m.text"
			#   content.body         # => "hello"
			#   content.membership   # => "join"
			#   content.avatar_url   # => "mxc://example.org/abc"
			#   content["custom"]    # => direct hash access for non-standard fields
			#
			class Content
				attr_reader :msgtype, :body, :membership

				def initialize(data)
					@data       = data
					@msgtype    = data["msgtype"]
					@body       = data["body"]
					@membership = data["membership"]
				end

				# Direct hash access for any content field.
				def [](key)
					@data[key.to_s]
				end

				# Returns the raw content hash.
				def to_h
					@data
				end

				# Dynamic access to any content field present in the raw data.
				def method_missing(name, *args)
					key = name.to_s
					if @data.key?(key)
						@data[key]
					else
						nil
					end
				end

				def respond_to_missing?(name, include_private = false)
					@data.key?(name.to_s) || super
				end
			end

			# Represents a Matrix event received via the Application Service API.
			#
			# Provides typed accessors for all envelope fields plus schema-driven
			# validation using the official Matrix spec YAML schemas.
			#
			#   event = Event.new(raw_hash)
			#   event.type           # => "m.room.message"
			#   event.sender         # => "@alice:example.org"
			#   event.content.body   # => "hello"
			#   event.valid?         # => true
			#   event.valid!         # => true (or raises Schema::ValidationError)
			#
			class Event
				attr_reader :type, :sender, :room_id, :state_key, :content,
				            :event_id, :origin_server_ts, :unsigned, :raw

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
				def schema
					Schema[@type]
				end

				# Validate this event against its schema.
				# Returns true if valid or if no schema exists (lenient).
				def valid?
					Schema.valid?(@raw)
				end

				# Validate this event against its schema.
				# Raises Schema::ValidationError with detailed errors on failure.
				# Returns true if valid or if no schema exists.
				def valid!
					errors = Schema.validate(@raw)
					unless errors.empty?
						raise Schema::ValidationError.new(
							errors,
							event_type: @type,
							event_id: @event_id
						)
					end
					true
				end

				# Content property names defined by the schema for this event type.
				# @return [Array<String>]
				def content_properties
					Schema.content_properties(@type)
				end

				# Is this a state event? (has a state_key)
				def state_event?
					!@state_key.nil?
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

		it "provides hash access via []" do
			content = Async::Matrix::ApplicationService::Content.new({"custom_field" => "value"})
			content["custom_field"].should == "value"
		end

		it "provides dynamic access via method_missing" do
			content = Async::Matrix::ApplicationService::Content.new({
				"avatar_url" => "mxc://example.org/abc",
				"displayname" => "Alice"
			})
			content.avatar_url.should == "mxc://example.org/abc"
			content.displayname.should == "Alice"
		end

		it "returns nil for unknown fields via method_missing" do
			content = Async::Matrix::ApplicationService::Content.new({})
			content.nonexistent.should.be.nil
		end

		it "returns the raw hash via to_h" do
			data = {"msgtype" => "m.text", "body" => "hi"}
			content = Async::Matrix::ApplicationService::Content.new(data)
			content.to_h.should == data
		end

		it "responds to keys present in the data" do
			content = Async::Matrix::ApplicationService::Content.new({"avatar_url" => "mxc://x/y"})
			content.respond_to?(:avatar_url).should == true
			content.respond_to?(:nonexistent).should == false
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
			event.content.should.be.kind_of Async::Matrix::ApplicationService::Content
			event.content.body.should == "hi"
		end

		it "defaults content to empty Content when missing" do
			event = Async::Matrix::ApplicationService::Event.new({"type" => "m.room.message"})
			event.content.should.be.kind_of Async::Matrix::ApplicationService::Content
			event.content.body.should.be.nil
		end

		it "exposes the raw hash" do
			data = {"type" => "m.room.message", "content" => {"body" => "hi", "msgtype" => "m.text"}}
			event = Async::Matrix::ApplicationService::Event.new(data)
			event.raw.should.equal data
		end

		it "detects state events" do
			state = Async::Matrix::ApplicationService::Event.new({"type" => "m.room.member", "state_key" => "@a:b"})
			state.state_event?.should == true

			msg = Async::Matrix::ApplicationService::Event.new({"type" => "m.room.message"})
			msg.state_event?.should == false
		end

		it "returns the schema for known event types" do
			event = Async::Matrix::ApplicationService::Event.new({"type" => "m.room.message", "content" => {}})
			event.schema.should.not.be.nil
			event.schema.should.be.kind_of JSONSchemer::Schema
		end

		it "returns nil schema for unknown event types" do
			event = Async::Matrix::ApplicationService::Event.new({"type" => "m.custom.event", "content" => {}})
			event.schema.should.be.nil
		end

		it "validates a correct event" do
			event = Async::Matrix::ApplicationService::Event.new({
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
			event = Async::Matrix::ApplicationService::Event.new({
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
			event = Async::Matrix::ApplicationService::Event.new({
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
			rescue Async::Matrix::Schema::ValidationError => e
				e.message.should.include "m.room.member"
				e.message.should.include "$abc123"
				e.errors.should.not.be.empty
			end
		end

		it "is lenient with unknown event types" do
			event = Async::Matrix::ApplicationService::Event.new({
				"type" => "com.custom.event",
				"content" => {"anything" => "goes"},
				"event_id" => "$x",
				"sender" => "@a:b"
			})
			event.valid?.should == true
			event.valid!.should == true
		end

		it "returns content properties for known types" do
			event = Async::Matrix::ApplicationService::Event.new({
				"type" => "m.room.member",
				"content" => {"membership" => "join"}
			})
			props = event.content_properties
			props.should.include "membership"
		end
	end
end
