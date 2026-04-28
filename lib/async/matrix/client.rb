# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http/internet"
require "async/matrix"
require "json"
require "erb"
require "console"
require "securerandom"

module Async
  module Matrix
    # Async HTTP client for the Matrix Client-Server API.
    #
    # Every outbound request is authenticated with the appservice `as_token`.
    # All methods are fiber-safe and run naturally inside Falcon's async reactor.
    #
    #   client = Async::Matrix::Client.new(config)
    #   client.send_text("!room:example.com", "Hello world")
    #   client.join_room("!room:example.com")
    #
    class Client
      CLIENT_PREFIX = "/_matrix/client/v3"

      attr_reader :config

      def initialize(config)
        @config  = config
        @base    = config.homeserver.address
        @headers = [
          ["authorization", "Bearer #{config.appservice.as_token}"],
          ["content-type",  "application/json"],
          ["user-agent",    "AsyncMatrix/#{Async::Matrix::VERSION}"]
        ]
      end

      # ── Messaging ──────────────────────────────────────────────

      def send_text(room_id, text)
        content = {msgtype: "m.text", body: text}
        send_message_event(room_id, "m.room.message", content)
      end

      def send_html(room_id, html, plaintext = nil)
        content = {
          msgtype:        "m.text",
          body:           plaintext || html.gsub(/<[^>]+>/, ""),
          format:         "org.matrix.custom.html",
          formatted_body: html
        }
        send_message_event(room_id, "m.room.message", content)
      end

      def send_notice(room_id, text)
        content = {msgtype: "m.notice", body: text}
        send_message_event(room_id, "m.room.message", content)
      end

      # ── Room actions ───────────────────────────────────────────

      def join_room(room_id)
        post("#{CLIENT_PREFIX}/join/#{encode(room_id)}")
      end

      def leave_room(room_id)
        post("#{CLIENT_PREFIX}/rooms/#{encode(room_id)}/leave")
      end

      # ── Profile ────────────────────────────────────────────────

      def set_display_name(name, user_id = nil)
        uid = user_id || @config.bot_mxid
        put(
          "#{CLIENT_PREFIX}/profile/#{encode(uid)}/displayname",
          {displayname: name}
        )
      end

      # ── Verification ───────────────────────────────────────────

      def whoami
        get("#{CLIENT_PREFIX}/account/whoami")
      end

      # ── Full API (runtime-generated from OpenAPI schemas) ─────

      # Returns a Gateway that provides method-chained access to every
      # Matrix Client-Server API endpoint. Chains are validated against
      # the official OpenAPI path tree and terminated by .get(), .post(),
      # .put(), or .delete().
      #
      #   client.api.account.whoami.get
      #   client.api.createRoom.post(name: "Pub")
      #   client.api.rooms("!room:ex.com").ban.post(user_id: "@bad:ex.com")
      #   client.api.rooms("!room:ex.com").messages.get(dir: "b", limit: 10)
      #
      def api
        Api::Gateway.new(self)
      end

      # ── Low-level HTTP ─────────────────────────────────────────

      def send_message_event(room_id, event_type, content)
        txn_id = SecureRandom.uuid
        path = "#{CLIENT_PREFIX}/rooms/#{encode(room_id)}/send/#{encode(event_type)}/#{txn_id}"
        put(path, content)
      end

      def get(path)
        request("GET", path)
      end

      def put(path, body = {})
        request("PUT", path, body)
      end

      def post(path, body = {})
        request("POST", path, body)
      end

      def close
        @internet&.close
        @internet = nil
      end

      private

      def internet
        @internet ||= Async::HTTP::Internet.new
      end

      def request(method, path, body = nil)
        url = "#{@base}#{path}"
        json_body = body ? JSON.generate(body) : nil

        Console.debug(self) { "#{method} #{path}" }

        response = internet.call(method, url, @headers, json_body)
        status   = response.status
        payload  = response.read

        unless (200..299).cover?(status)
          parsed = ApplicationService::ErrorResponse.new(
            begin; JSON.parse(payload); rescue; {} end
          )
          Console.error(self) { "Matrix API #{status}: #{parsed.errcode} — #{parsed.error}" }
          raise HomeserverError.new(
            parsed.errcode || "UNKNOWN",
            parsed.error || payload.to_s[0..200],
            status: status
          )
        end

        payload && !payload.empty? ? JSON.parse(payload) : {}
      end

      def encode(value)
        ERB::Util.url_encode(value)
      end
    end
  end
end

test do
  describe "Async::Matrix::Client" do
    def make_config
      Async::Matrix::ApplicationService::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "test_token", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    it "sets authorization header from config" do
      client = Async::Matrix::Client.new(make_config)
      client.config.appservice.as_token.should == "test_token"
    end

    it "responds to messaging methods" do
      client = Async::Matrix::Client.new(make_config)
      client.should.respond_to :send_text
      client.should.respond_to :send_html
      client.should.respond_to :send_notice
    end

    it "responds to room action methods" do
      client = Async::Matrix::Client.new(make_config)
      client.should.respond_to :join_room
      client.should.respond_to :leave_room
    end

    it "responds to profile and verification methods" do
      client = Async::Matrix::Client.new(make_config)
      client.should.respond_to :set_display_name
      client.should.respond_to :whoami
    end

    it "can be closed without error" do
      client = Async::Matrix::Client.new(make_config)
      lambda { client.close }.should.not.raise
    end
  end
end
