# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async"
require "async/http/endpoint"
require "async/websocket/client"
require "json"
require "console"
require "async/discord"

module Async
  module Discord
    # WebSocket client for the Discord Gateway (v10).
    #
    # Connects to Discord's WebSocket gateway, authenticates with a bot token,
    # manages heartbeating, and dispatches incoming events to registered handlers.
    #
    # Supports session resumption on reconnect.
    #
    #   gateway = Async::Discord::Gateway.new(token: "MTk...", intents: 0x30001)
    #   gateway.on("MESSAGE_CREATE") { |data| puts data["content"] }
    #   gateway.on("READY") { |data| puts "Connected as #{data["user"]["username"]}" }
    #   gateway.run  # blocks, runs inside Async reactor
    #
    class Gateway
      GATEWAY_URL = "wss://gateway.discord.gg/?v=10&encoding=json"

      # Discord Gateway opcodes
      DISPATCH           = 0
      HEARTBEAT          = 1
      IDENTIFY           = 2
      PRESENCE_UPDATE    = 3
      VOICE_STATE_UPDATE = 4
      RESUME             = 6
      RECONNECT          = 7
      REQUEST_GUILD_MEMBERS = 8
      INVALID_SESSION    = 9
      HELLO              = 10
      HEARTBEAT_ACK      = 11

      attr_reader :session_id, :seq

      def initialize(token:, intents:, gateway_url: GATEWAY_URL)
        @token       = token
        @intents     = intents
        @gateway_url = gateway_url
        @handlers    = Hash.new { |h, k| h[k] = [] }
        @seq         = nil
        @session_id  = nil
        @resume_url  = nil
        @heartbeat_interval = nil
        @heartbeat_acked    = true
        @connection  = nil
        @running     = false
      end

      # Register a handler for a Discord event type.
      #
      #   gateway.on("MESSAGE_CREATE") { |data| ... }
      #   gateway.on("READY") { |data| ... }
      #
      def on(event_type, &block)
        @handlers[event_type] << block
      end

      # Connect to the gateway and run the event loop.
      # Blocks until the connection is closed or an unrecoverable error occurs.
      # Must be called inside an Async reactor.
      def run
        @running = true

        while @running
          begin
            connect_and_run
          rescue => e
            Console.error(self) { "Gateway error: #{e.class}: #{e.message}" }
            break unless @running
            sleep(5)
          end
        end
      end

      # Gracefully stop the gateway.
      def stop
        @running = false
        @connection&.close
      end

      # Send a raw payload to the gateway.
      def send_payload(op:, d: nil)
        return unless @connection

        payload = {op: op, d: d}
        @connection.write(payload.to_json)
        @connection.flush
      end

      private

        def connect_and_run
          url = @resume_url || @gateway_url
          endpoint = Async::HTTP::Endpoint.parse(url)

          Console.info(self) { "Connecting to #{url}" }

          Async::WebSocket::Client.connect(endpoint) do |connection|
            @connection = connection

            # First message should be HELLO
            hello = read_message
            unless hello && hello["op"] == HELLO
              raise GatewayError.new("GATEWAY", "Expected HELLO, got: #{hello&.dig("op")}")
            end

            @heartbeat_interval = hello["d"]["heartbeat_interval"] / 1000.0
            Console.info(self) { "Heartbeat interval: #{@heartbeat_interval}s" }

            # Start heartbeat fiber
            heartbeat_task = Async do
              heartbeat_loop
            end

            # Identify or resume
            if @session_id && @seq
              send_resume
            else
              send_identify
            end

            # Read events until disconnected
            read_loop

          ensure
            heartbeat_task&.stop
            @connection = nil
          end
        end

        def read_message
          message = @connection.read
          return nil unless message

          JSON.parse(message.to_str)
        rescue => e
          Console.error(self) { "Failed to read/parse gateway message: #{e.message}" }
          nil
        end

        def read_loop
          loop do
            payload = read_message
            break unless payload

            handle_payload(payload)
          end
        end

        def handle_payload(payload)
          op   = payload["op"]
          data = payload["d"]
          seq  = payload["s"]
          type = payload["t"]

          @seq = seq if seq

          case op
          when DISPATCH
            Console.debug(self) { "DISPATCH: #{type}" }
            dispatch(type, data)

          when HEARTBEAT
            # Server is asking us to heartbeat immediately
            send_heartbeat

          when RECONNECT
            Console.info(self) { "Server requested reconnect" }
            @connection&.close

          when INVALID_SESSION
            resumable = data == true
            Console.warn(self) { "Invalid session (resumable=#{resumable})" }
            unless resumable
              @session_id = nil
              @seq = nil
            end
            sleep(rand(1.0..5.0))
            @connection&.close

          when HEARTBEAT_ACK
            @heartbeat_acked = true

          else
            Console.debug(self) { "Unknown opcode: #{op}" }
          end
        end

        def dispatch(event_type, data)
          case event_type
          when "READY"
            @session_id = data["session_id"]
            @resume_url = data["resume_gateway_url"]
            Console.info(self) { "Ready: session=#{@session_id}" }
          when "RESUMED"
            Console.info(self) { "Resumed successfully" }
          end

          @handlers[event_type].each do |handler|
            begin
              handler.call(data)
            rescue => e
              Console.error(self) { "Handler for #{event_type} raised: #{e.class}: #{e.message}" }
            end
          end
        end

        def send_identify
          send_payload(
            op: IDENTIFY,
            d: {
              token: @token,
              intents: @intents,
              properties: {
                os: RUBY_PLATFORM,
                browser: "async-discord",
                device: "async-discord"
              }
            }
          )
        end

        def send_resume
          Console.info(self) { "Resuming session #{@session_id} at seq #{@seq}" }
          send_payload(
            op: RESUME,
            d: {
              token: @token,
              session_id: @session_id,
              seq: @seq
            }
          )
        end

        def send_heartbeat
          send_payload(op: HEARTBEAT, d: @seq)
          @heartbeat_acked = false
        end

        def heartbeat_loop
          # Jitter the first heartbeat as per Discord docs
          sleep(@heartbeat_interval * rand)
          send_heartbeat

          loop do
            sleep(@heartbeat_interval)

            unless @heartbeat_acked
              Console.warn(self) { "Heartbeat not ACKed, reconnecting" }
              @connection&.close
              break
            end

            send_heartbeat
          end
        end
    end
  end
end

test do
  describe "Async::Discord::Gateway" do
    it "initializes with token and intents" do
      gw = Async::Discord::Gateway.new(token: "test_token", intents: 0x30001)
      gw.session_id.should.be.nil
      gw.seq.should.be.nil
    end

    it "registers event handlers" do
      gw = Async::Discord::Gateway.new(token: "test_token", intents: 0)
      received = []
      gw.on("MESSAGE_CREATE") { |data| received << data }
      gw.on("MESSAGE_CREATE") { |data| received << :second }

      # Dispatch manually via send to test handler registration
      gw.send(:dispatch, "MESSAGE_CREATE", {"content" => "hello"})
      received.length.should == 2
      received[0]["content"].should == "hello"
      received[1].should == :second
    end

    it "handles READY event and stores session_id" do
      gw = Async::Discord::Gateway.new(token: "test_token", intents: 0)
      ready_data = {
        "session_id" => "abc123",
        "resume_gateway_url" => "wss://resume.discord.gg",
        "user" => {"username" => "testbot"}
      }

      gw.send(:dispatch, "READY", ready_data)
      gw.session_id.should == "abc123"
    end

    it "updates seq from dispatch payloads" do
      gw = Async::Discord::Gateway.new(token: "test_token", intents: 0)
      gw.send(:handle_payload, {
        "op" => 0,
        "d" => {"content" => "hi"},
        "s" => 42,
        "t" => "MESSAGE_CREATE"
      })
      gw.seq.should == 42
    end

    it "clears session on non-resumable INVALID_SESSION" do
      gw = Async::Discord::Gateway.new(token: "test_token", intents: 0)
      # Set a session first
      gw.send(:dispatch, "READY", {
        "session_id" => "sess123",
        "resume_gateway_url" => "wss://resume.discord.gg"
      })
      gw.session_id.should == "sess123"

      # Simulate non-resumable invalid session (stub connection close)
      gw.instance_variable_set(:@connection, nil)
      gw.send(:handle_payload, {
        "op" => Async::Discord::Gateway::INVALID_SESSION,
        "d" => false,
        "s" => nil,
        "t" => nil
      })
      gw.session_id.should.be.nil
      gw.seq.should.be.nil
    end

    it "continues dispatching when a handler raises" do
      gw = Async::Discord::Gateway.new(token: "test_token", intents: 0)
      results = []
      gw.on("TEST") { |_| raise "boom" }
      gw.on("TEST") { |data| results << data }

      gw.send(:dispatch, "TEST", {"value" => 1})
      results.length.should == 1
      results.first["value"].should == 1
    end

    it "responds to stop" do
      gw = Async::Discord::Gateway.new(token: "test_token", intents: 0)
      gw.should.respond_to :stop
    end

    it "accepts custom gateway URL" do
      gw = Async::Discord::Gateway.new(
        token: "tok",
        intents: 0,
        gateway_url: "wss://custom.gateway.example.com"
      )
      gw.instance_variable_get(:@gateway_url).should == "wss://custom.gateway.example.com"
    end
  end
end
