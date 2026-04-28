# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "console"
require "async/matrix"

module Async
  module Matrix
    module ApplicationService
      # DSL wrapper that pairs a Client with event handlers.
      #
      # A Bot produces handler objects that conform to the Dispatcher's
      # duck-type contract (#event_types, #call). Register a bot on a
      # Server (or Dispatcher) the same way you would register a plain handler.
      #
      #   bot = Bot.new(client) do
      #     on "m.room.member" do |event|
      #       join_room(event.room_id) if event.content.membership == "invite"
      #     end
      #
      #     on "m.room.message", msgtype: "m.text", not_from: :self do |event|
      #       send_notice event.room_id, "Echo: #{event.content.body}"
      #     end
      #   end
      #
      #   server.register(bot)
      #
      class Bot
        attr_reader :client, :handlers

        def initialize(client, &block)
          @client   = client
          @handlers = []

          instance_eval(&block) if block
        end

        # Register a handler block for one or more event types.
        #
        # Filters (all optional):
        #   msgtype:  — only dispatch when content.msgtype matches (e.g. "m.text")
        #   not_from: — :self skips events sent by this bot's own MXID
        #
        def on(*event_types, msgtype: nil, not_from: nil, &block)
          raise ArgumentError, "on requires at least one event type" if event_types.empty?
          raise ArgumentError, "on requires a block" unless block

          handler = Handler.new(
            bot:         self,
            event_types: event_types.flatten,
            msgtype:     msgtype,
            not_from:    not_from,
            block:       block
          )

          @handlers << handler
          handler
        end

        # Internal handler object produced by the #on DSL method.
        # Conforms to the Dispatcher duck-type: #event_types, #call.
        class Handler
          attr_reader :event_types

          def initialize(bot:, event_types:, msgtype:, not_from:, block:)
            @bot         = bot
            @event_types = event_types
            @msgtype     = msgtype
            @not_from    = not_from
            @block       = block
          end

          def call(event)
            return if @msgtype  && event.content&.msgtype != @msgtype
            return if @not_from == :self && event.sender == @bot.client.config.bot_mxid

            # Execute the block in a context that has helper methods
            Context.new(@bot.client).execute(event, &@block)
          end
        end

        # Execution context for handler blocks.
        # Provides helper methods so blocks can call send_notice, join_room, etc.
        # directly without holding a reference to the client.
        class Context
          def initialize(client)
            @client = client
          end

          def execute(event, &block)
            @event = event
            instance_exec(event, &block)
          end

          def send_text(room_id, text)
            @client.send_text(room_id, text)
          end

          def send_html(room_id, html, plaintext = nil)
            @client.send_html(room_id, html, plaintext)
          end

          def send_notice(room_id, text)
            @client.send_notice(room_id, text)
          end

          def join_room(room_id)
            @client.join_room(room_id)
          end

          def leave_room(room_id)
            @client.leave_room(room_id)
          end

          def set_display_name(name, user_id = nil)
            @client.set_display_name(name, user_id)
          end

          def client
            @client
          end
        end
      end
    end
  end
end

test do
  describe "Async::Matrix::ApplicationService::Bot" do
    def make_config
      Async::Matrix::ApplicationService::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "token_secret", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    def make_event(type:, sender: "@user:localhost", msgtype: nil, body: nil, membership: nil, state_key: nil)
      data = {"type" => type, "sender" => sender, "room_id" => "!room:localhost"}
      content = {}
      content["msgtype"]    = msgtype    if msgtype
      content["body"]       = body       if body
      content["membership"] = membership if membership
      data["state_key"] = state_key if state_key
      data["content"] = content
      Async::Matrix::ApplicationService::Event.new(data)
    end

    it "registers handlers via the on DSL" do
      config = make_config
      client = Async::Matrix::Client.new(config)

      bot = Async::Matrix::ApplicationService::Bot.new(client) do
        on "m.room.message" do |event|
          # no-op
        end
      end

      bot.handlers.length.should == 1
      bot.handlers.first.event_types.should == ["m.room.message"]
    end

    it "registers multiple event types on a single handler" do
      config = make_config
      client = Async::Matrix::Client.new(config)

      bot = Async::Matrix::ApplicationService::Bot.new(client) do
        on "m.room.message", "m.room.member" do |event|
          # no-op
        end
      end

      bot.handlers.first.event_types.should == ["m.room.message", "m.room.member"]
    end

    it "filters by msgtype" do
      config = make_config
      client = Async::Matrix::Client.new(config)
      received = []

      bot = Async::Matrix::ApplicationService::Bot.new(client) do
        on "m.room.message", msgtype: "m.text" do |event|
          received << event.content.body
        end
      end

      handler = bot.handlers.first
      handler.call(make_event(type: "m.room.message", msgtype: "m.text", body: "hello"))
      handler.call(make_event(type: "m.room.message", msgtype: "m.notice", body: "ignored"))

      received.should == ["hello"]
    end

    it "filters out self with not_from: :self" do
      config = make_config
      client = Async::Matrix::Client.new(config)
      received = []

      bot = Async::Matrix::ApplicationService::Bot.new(client) do
        on "m.room.message", not_from: :self do |event|
          received << event.content.body
        end
      end

      handler = bot.handlers.first
      handler.call(make_event(type: "m.room.message", sender: "@user:localhost", msgtype: "m.text", body: "yes"))
      handler.call(make_event(type: "m.room.message", sender: "@bot:localhost", msgtype: "m.text", body: "no"))

      received.should == ["yes"]
    end

    it "raises if on is called without event types" do
      config = make_config
      client = Async::Matrix::Client.new(config)

      lambda {
        Async::Matrix::ApplicationService::Bot.new(client) do
          on do |event|; end
        end
      }.should.raise(ArgumentError)
    end

    it "raises if on is called without a block" do
      config = make_config
      client = Async::Matrix::Client.new(config)

      lambda {
        bot = Async::Matrix::ApplicationService::Bot.new(client)
        bot.on "m.room.message"
      }.should.raise(ArgumentError)
    end
  end
end
