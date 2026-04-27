# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "console"

# Minimal Matrix module providing the interfaces expected by the echo bot example.
# This will be replaced by the full async-matrix library as it matures.
module Matrix
	def self.logger
		Console
	end

	module Errors
		class Base < StandardError
			attr_reader :errcode, :status

			def initialize(errcode, message, status: nil)
				@errcode = errcode
				@status = status
				super(message)
			end
		end

		class NotFound < Base; end
		class BadJson < Base; end
		class Auth < Base; end
		class Homeserver < Base; end
	end

	module ApplicationService
		module Models
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

			class Content
				attr_reader :msgtype, :body, :membership

				def initialize(data)
					@msgtype    = data["msgtype"]
					@body       = data["body"]
					@membership = data["membership"]
				end
			end

			class Transaction
				attr_reader :events, :ephemeral

				def initialize(data)
					@events    = (data["events"] || []).map { |e| Event.new(e) }
					@ephemeral = (data["de.sorunome.msc2409.ephemeral"] || data["ephemeral"] || []).map { |e| Event.new(e) }
				end
			end

			class ErrorResponse
				attr_reader :errcode, :error

				def initialize(data)
					@errcode = data["errcode"]
					@error   = data["error"]
				end
			end
		end
	end
end

test do
	# --- Errors ---

	describe "Matrix::Errors" do
		it "stores errcode and message" do
			err = Matrix::Errors::Base.new("M_UNKNOWN", "something broke")
			err.errcode.should == "M_UNKNOWN"
			err.message.should == "something broke"
		end

		it "stores optional status" do
			err = Matrix::Errors::Base.new("M_UNKNOWN", "bad", status: 400)
			err.status.should == 400
		end

		it "defaults status to nil" do
			Matrix::Errors::Base.new("M_UNKNOWN", "bad").status.should.be.nil
		end

		it "is a StandardError" do
			Matrix::Errors::Base.new("M_UNKNOWN", "bad").should.be.kind_of StandardError
		end

		it "NotFound inherits from Base" do
			Matrix::Errors::NotFound.new("M_NOT_FOUND", "gone").should.be.kind_of Matrix::Errors::Base
		end

		it "BadJson inherits from Base" do
			Matrix::Errors::BadJson.new("M_BAD_JSON", "invalid").should.be.kind_of Matrix::Errors::Base
		end

		it "Auth inherits from Base" do
			Matrix::Errors::Auth.new("M_FORBIDDEN", "denied").should.be.kind_of Matrix::Errors::Base
		end

		it "Homeserver inherits from Base" do
			Matrix::Errors::Homeserver.new("M_UNKNOWN", "upstream").should.be.kind_of Matrix::Errors::Base
		end
	end

	# --- Content ---

	describe "Matrix::ApplicationService::Models::Content" do
		it "parses msgtype, body, and membership" do
			content = Matrix::ApplicationService::Models::Content.new({
				"msgtype" => "m.text",
				"body" => "hello",
				"membership" => "join"
			})
			content.msgtype.should == "m.text"
			content.body.should == "hello"
			content.membership.should == "join"
		end

		it "handles missing fields gracefully" do
			content = Matrix::ApplicationService::Models::Content.new({})
			content.msgtype.should.be.nil
			content.body.should.be.nil
			content.membership.should.be.nil
		end
	end

	# --- Event ---

	describe "Matrix::ApplicationService::Models::Event" do
		it "parses all event fields" do
			event = Matrix::ApplicationService::Models::Event.new({
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
			event.content.should.be.kind_of Matrix::ApplicationService::Models::Content
			event.content.body.should == "hi"
		end

		it "defaults content to empty Content when missing" do
			event = Matrix::ApplicationService::Models::Event.new({"type" => "m.room.message"})
			event.content.should.be.kind_of Matrix::ApplicationService::Models::Content
			event.content.body.should.be.nil
		end
	end

	# --- Transaction ---

	describe "Matrix::ApplicationService::Models::Transaction" do
		it "wraps events array" do
			txn = Matrix::ApplicationService::Models::Transaction.new({
				"events" => [
					{"type" => "m.room.message", "content" => {"body" => "one"}},
					{"type" => "m.room.message", "content" => {"body" => "two"}}
				]
			})
			txn.events.length.should == 2
			txn.events.first.content.body.should == "one"
			txn.events.last.content.body.should == "two"
		end

		it "defaults to empty events when missing" do
			txn = Matrix::ApplicationService::Models::Transaction.new({})
			txn.events.should.be.empty
		end

		it "parses MSC2409 ephemeral events" do
			txn = Matrix::ApplicationService::Models::Transaction.new({
				"events" => [],
				"de.sorunome.msc2409.ephemeral" => [
					{"type" => "m.typing", "content" => {}}
				]
			})
			txn.ephemeral.length.should == 1
			txn.ephemeral.first.type.should == "m.typing"
		end

		it "falls back to ephemeral key" do
			txn = Matrix::ApplicationService::Models::Transaction.new({
				"events" => [],
				"ephemeral" => [
					{"type" => "m.receipt", "content" => {}}
				]
			})
			txn.ephemeral.length.should == 1
			txn.ephemeral.first.type.should == "m.receipt"
		end

		it "defaults to empty ephemeral when missing" do
			txn = Matrix::ApplicationService::Models::Transaction.new({"events" => []})
			txn.ephemeral.should.be.empty
		end
	end

	# --- ErrorResponse ---

	describe "Matrix::ApplicationService::Models::ErrorResponse" do
		it "parses errcode and error" do
			resp = Matrix::ApplicationService::Models::ErrorResponse.new({
				"errcode" => "M_FORBIDDEN",
				"error" => "Access denied"
			})
			resp.errcode.should == "M_FORBIDDEN"
			resp.error.should == "Access denied"
		end

		it "handles missing fields" do
			resp = Matrix::ApplicationService::Models::ErrorResponse.new({})
			resp.errcode.should.be.nil
			resp.error.should.be.nil
		end
	end
end
