# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"

module Async
	module Matrix
		module ApplicationService
			class Transaction
				attr_reader :events, :ephemeral

				def initialize(data)
					@events    = (data["events"] || []).map { |e| Event.new(e) }
					@ephemeral = (data["de.sorunome.msc2409.ephemeral"] || data["ephemeral"] || []).map { |e| Event.new(e) }
				end
			end
		end
	end
end

test do
	describe "Async::Matrix::ApplicationService::Transaction" do
		it "wraps events array" do
			txn = Async::Matrix::ApplicationService::Transaction.new({
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
			txn = Async::Matrix::ApplicationService::Transaction.new({})
			txn.events.should.be.empty
		end

		it "parses MSC2409 ephemeral events" do
			txn = Async::Matrix::ApplicationService::Transaction.new({
				"events" => [],
				"de.sorunome.msc2409.ephemeral" => [
					{"type" => "m.typing", "content" => {}}
				]
			})
			txn.ephemeral.length.should == 1
			txn.ephemeral.first.type.should == "m.typing"
		end

		it "falls back to ephemeral key" do
			txn = Async::Matrix::ApplicationService::Transaction.new({
				"events" => [],
				"ephemeral" => [
					{"type" => "m.receipt", "content" => {}}
				]
			})
			txn.ephemeral.length.should == 1
			txn.ephemeral.first.type.should == "m.receipt"
		end

		it "defaults to empty ephemeral when missing" do
			txn = Async::Matrix::ApplicationService::Transaction.new({"events" => []})
			txn.ephemeral.should.be.empty
		end
	end
end
