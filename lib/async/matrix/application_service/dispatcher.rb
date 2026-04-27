# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "console"
require_relative "transaction"

module Async
	module Matrix
		module ApplicationService
			# Routes incoming Matrix events to registered handler objects.
			#
			# Each handler declares the event types it handles via `#event_types`.
			# When an event arrives, the dispatcher finds all matching handlers
			# and calls them. Errors in one handler do not prevent others from running.
			class Dispatcher
				def initialize
					@handlers = Hash.new { |h, k| h[k] = [] }
				end

				def register(handler)
					handler.event_types.each do |type|
						@handlers[type] << handler
						Console.info(self) { "Registered #{handler.class.name} for #{type}" }
					end
				end

				def dispatch(event)
					type     = event.type
					handlers = @handlers[type]

					if handlers.empty?
						Console.debug(self) { "No handler for event type: #{type}" }
						return
					end

					handlers.each do |handler|
						handler.call(event)
					rescue => e
						Console.error(self) { "Handler #{handler.class.name} raised #{e.class}: #{e.message}" }
					end
				end

				def dispatch_transaction(body)
					txn = Transaction.new(body)
					txn.events.each    { |event| dispatch(event) }
					txn.ephemeral.each { |event| dispatch(event) }
				end

				def handler_count
					@handlers.values.flatten.size
				end
			end
		end
	end
end

test do
	describe "Async::Matrix::ApplicationService::Dispatcher" do
		it "registers and dispatches to handlers" do
			received = []
			handler = Object.new
			handler.define_singleton_method(:event_types) { ["m.room.message"] }
			handler.define_singleton_method(:call) { |event| received << event }

			dispatcher = Async::Matrix::ApplicationService::Dispatcher.new
			dispatcher.register(handler)
			dispatcher.handler_count.should == 1

			event = Async::Matrix::ApplicationService::Event.new({
				"type" => "m.room.message",
				"content" => {"body" => "hi"}
			})
			dispatcher.dispatch(event)
			received.length.should == 1
			received.first.content.body.should == "hi"
		end

		it "ignores events with no matching handler" do
			dispatcher = Async::Matrix::ApplicationService::Dispatcher.new
			event = Async::Matrix::ApplicationService::Event.new({"type" => "m.unknown"})
			lambda { dispatcher.dispatch(event) }.should.not.raise
		end

		it "continues dispatching when a handler raises" do
			results = []
			bad_handler = Object.new
			bad_handler.define_singleton_method(:event_types) { ["m.room.message"] }
			bad_handler.define_singleton_method(:call) { |_| raise "boom" }

			good_handler = Object.new
			good_handler.define_singleton_method(:event_types) { ["m.room.message"] }
			good_handler.define_singleton_method(:call) { |e| results << e }

			dispatcher = Async::Matrix::ApplicationService::Dispatcher.new
			dispatcher.register(bad_handler)
			dispatcher.register(good_handler)

			event = Async::Matrix::ApplicationService::Event.new({
				"type" => "m.room.message",
				"content" => {"body" => "test"}
			})
			dispatcher.dispatch(event)
			results.length.should == 1
		end

		it "dispatches a full transaction" do
			received = []
			handler = Object.new
			handler.define_singleton_method(:event_types) { ["m.room.message"] }
			handler.define_singleton_method(:call) { |e| received << e }

			dispatcher = Async::Matrix::ApplicationService::Dispatcher.new
			dispatcher.register(handler)

			dispatcher.dispatch_transaction({
				"events" => [
					{"type" => "m.room.message", "content" => {"body" => "one"}},
					{"type" => "m.room.message", "content" => {"body" => "two"}}
				]
			})
			received.length.should == 2
		end
	end
end
