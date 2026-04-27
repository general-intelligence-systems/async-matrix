# frozen_string_literal: true

require "async/http/internet"
require "json"
require "erb"

module EchoBot
  # Async HTTP client for the Matrix Client-Server API.
  #
  # Every outbound request is authenticated with the appservice `as_token`.
  # All methods are fiber-safe and run naturally inside Falcon's async reactor.
  class Client
    CLIENT_PREFIX = "/_matrix/client/v3"

    attr_reader :config

    def initialize(config)
      @config  = config
      @base    = config.homeserver_url
      @headers = [
        ["authorization", "Bearer #{config.as_token}"],
        ["content-type",  "application/json"],
        ["user-agent",    "EchoBot/0.1"]
      ]
    end

    # ── Messaging ──────────────────────────────────────────────

    def send_text(room_id, text)
      content = { msgtype: "m.text", body: text }
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
      content = { msgtype: "m.notice", body: text }
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
        { displayname: name }
      )
    end

    # ── Verification ───────────────────────────────────────────

    def whoami
      get("#{CLIENT_PREFIX}/account/whoami")
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

        Matrix.logger.debug { "#{method} #{path}" }

        response = internet.call(method, url, @headers, json_body)
        status   = response.status
        payload  = response.read

        unless (200..299).cover?(status)
          parsed = Matrix::ApplicationService::Models::ErrorResponse.new(
            begin; JSON.parse(payload); rescue; {} end
          )
          Matrix.logger.error { "Matrix API #{status}: #{parsed.errcode} — #{parsed.error}" }
          raise Matrix::Errors::Homeserver.new(
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
