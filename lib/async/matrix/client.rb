# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/http/internet"
require "json"
require "erb"
require "console"
require "securerandom"
require "time"

# The action surface, mixed in below. Required explicitly because the library's
# loader globs this directory in sorted order, which reaches client.rb before
# client/ -- so `include Encryption` would resolve against nothing.
require_relative "client/encryption"
require_relative "client/rooms"

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

      # Retry defaults
      DEFAULT_MAX_RETRIES     = 3    # max retry attempts (0 disables)
      DEFAULT_RETRY_BASE      = 0.5  # initial backoff in seconds
      DEFAULT_MAX_RETRY_DELAY = 30   # cap on any single delay in seconds

      # Status codes eligible for retry
      RATE_LIMIT_STATUS      = 429
      GATEWAY_ERROR_STATUSES = [502, 503, 504].freeze

      # Response size limits (bytes)
      DEFAULT_RESPONSE_SIZE_LIMIT       = 50 * 1024 * 1024  # 50 MiB for JSON API responses
      DEFAULT_ERROR_RESPONSE_SIZE_LIMIT = 512 * 1024         # 512 KiB for error bodies

      include Encryption
      include Rooms

      attr_reader :config

      def initialize(config, max_retries: DEFAULT_MAX_RETRIES,
                     retry_base_delay: DEFAULT_RETRY_BASE,
                     max_retry_delay: DEFAULT_MAX_RETRY_DELAY,
                     ignore_rate_limit: false,
                     response_size_limit: DEFAULT_RESPONSE_SIZE_LIMIT,
                     error_response_size_limit: DEFAULT_ERROR_RESPONSE_SIZE_LIMIT)
        @config                   = config
        @base                     = config.homeserver.address
        @max_retries              = max_retries
        @retry_base_delay         = retry_base_delay
        @max_retry_delay          = max_retry_delay
        @ignore_rate_limit        = ignore_rate_limit
        @response_size_limit      = response_size_limit
        @error_response_size_limit = error_response_size_limit
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
          formatted_body: html,
        }
        send_message_event(room_id, "m.room.message", content)
      end

      def send_notice(room_id, text)
        content = {msgtype: "m.notice", body: text}
        send_message_event(room_id, "m.room.message", content)
      end

      # ── Room actions ───────────────────────────────────────────

      # Positional OR keyword: `join_room("!r:example.org")` is how this was
      # always called, and `join_room(room_id: "!r:example.org")` is the form
      # every other action here takes. Keeping both means the action surface is
      # consistent without breaking callers written against 3.0.
      def join_room(room_id = nil, **options)
        target = room_id || options[:room_id]
        post("#{CLIENT_PREFIX}/join/#{encode(target)}")
      end

      def leave_room(room_id = nil, **options)
        target = room_id || options[:room_id]
        post("#{CLIENT_PREFIX}/rooms/#{encode(target)}/leave")
      end

      # ── Profile ────────────────────────────────────────────────

      def set_display_name(name, user_id = nil)
        uid = user_id || @config.bot_mxid
        put(
          "#{CLIENT_PREFIX}/profile/#{encode(uid)}/displayname",
          {displayname: name},
        )
      end

      # ── Verification ───────────────────────────────────────────

      def whoami
        get("#{CLIENT_PREFIX}/account/whoami")
      end

      # ── Syncing ────────────────────────────────────────────────────────────

      # A stream of messages from this account, decrypted by +store+.
      #
      #   client.sync(store: device_store).each do |message|
      #     ...
      #   end
      #
      # See Client::Sync: the stream yields room messages only, and to-device
      # events are fed to the store on the way through, which is how room keys
      # arrive.
      def sync(store: nil, since: nil, timeout: Sync::DEFAULT_TIMEOUT, filter: nil)
        Sync.new(self, store: store, since: since, timeout: timeout, filter: filter)
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

      # Returns a Gateway rooted at /_matrix/media/v3 for media operations.
      # Binary routes (upload/download/thumbnail) are automatically detected
      # by the Chain and dispatched to the MediaClient.
      #
      #   client.media.upload.post(bytes, content_type: "image/png")
      #   client.media.download("example.com", "abc123").get
      #   client.media.thumbnail("example.com", "abc123").get(width: 64, height: 64)
      #
      def media
        Api::Gateway.new(self, prefix: %w[_matrix media v3])
      end

      # Returns the binary media client used for upload/download operations.
      # Lazily initialized, shares the same config as this client.
      def media_client
        @media_client ||= MediaClient.new(@config)
      end

      # ── Low-level HTTP ─────────────────────────────────────────

      def send_message_event(room_id, event_type, content)
        txn_id = SecureRandom.uuid
        path = "#{CLIENT_PREFIX}/rooms/#{encode(room_id)}/send/#{encode(event_type)}/#{txn_id}"
        put(path, content)
      end

      def get(path, max_retries: nil)
        request(
          "GET",
          path,
          nil,
          max_retries: max_retries,
        )
      end

      def put(path, body = {}, max_retries: nil)
        request(
          "PUT",
          path,
          body,
          max_retries: max_retries,
        )
      end

      def post(path, body = {}, max_retries: nil)
        request(
          "POST",
          path,
          body,
          max_retries: max_retries,
        )
      end

      # Query parameters added to EVERY request this client makes.
      #
      # EMPTY FOR AN ORDINARY CLIENT: a user's own access token already says who
      # the request is for. AppServiceClient overrides it, because an as_token
      # says only "an appservice" -- without `?user_id=` the homeserver assumes
      # the registration's sender_localpart, and without `?device_id=` the
      # request has no device at all, which fails precisely the calls encryption
      # depends on.
      def default_query = {}

      def close
        @internet&.close
        @internet = nil
        @media_client&.close
        @media_client = nil
      end

      private

        def internet
          @internet ||= Async::HTTP::Internet.new
        end

        # Merge #default_query into a path that may already carry a query --
        # Api::Chain appends its own parameters before handing the path over, so
        # this is the single place both routes pass through.
        #
        # A parameter the caller already set WINS. Overwriting it would mean a
        # client silently acting as somebody other than the caller asked for,
        # which is worse than the request failing.
        def apply_default_query(path)
          missing = default_query.reject { |key, _|
            path.match?(/[?&]#{Regexp.escape(key.to_s)}=/)
          }

          if missing.empty?
            path
          else
            if path.include?("?")
              separator = "&"
            else
              separator = "?"
            end

            pairs = missing.map { |key, value| "#{encode(key.to_s)}=#{encode(value.to_s)}" }

            "#{path}#{separator}#{pairs.join('&')}"
          end
        end

        # PUBLIC, declared below: Api::Chain#execute calls `@client.request` for
        # DELETE, so leaving this private makes every DELETE through the chain
        # raise NoMethodError.
        def request(method, path, body = nil, max_retries: nil)
          url = "#{@base}#{apply_default_query(path)}"
          if body
            json_body = JSON.generate(body)
          else
            json_body = nil
          end
          effective_max_retries = max_retries || @max_retries

          Console.debug(self) { "#{method} #{path}" }

          attempt = 0
          loop do
            response = internet.call(
              method,
              url,
              @headers,
              json_body,
            )
            status   = response.status

            if (200..299).cover?(status)
              payload = read_limited(response, @response_size_limit)

              if payload && !payload.empty?
                break JSON.parse(payload)
              else
                break {}
              end
            end

            attempt += 1

            if attempt <= effective_max_retries && retryable_status?(status)
              delay = compute_retry_delay(status, response, attempt)
              Console.warn(self) {
                "#{method} #{path} returned #{status}, retry #{attempt}/#{effective_max_retries} in #{delay.round(2)}s"
              }
              if response.respond_to?(:close)
                response.close
              end
              sleep(delay)
              next
            end

            payload = read_limited(response, @error_response_size_limit)
            parsed = ErrorResponse.new(
              begin; JSON.parse(payload); rescue; {} end,
            )
            Console.error(self) { "Matrix API #{status}: #{parsed.errcode} — #{parsed.error}" }
            raise HomeserverError.new(
              parsed.errcode || "UNKNOWN",
              parsed.error || payload.to_s[0..200],
              status: status,
            )
          end
        end

      # ── Response size limiting ──────────────────────────────────

      # Read the response body with a size limit. Raises ResponseTooLargeError
      # if the body exceeds the limit. Checks Content-Length first (fast path),
      # then enforces during streaming read (safe path).
      #
      # @param response [Protocol::HTTP::Response] the HTTP response
      # @param limit [Integer] maximum allowed body size in bytes
      # @return [String, nil] the response body, or nil if empty
        def read_limited(response, limit)
          body = response.body
          if body
            if body.respond_to?(:length) && body.length && body.length > limit
              body.close
              raise ResponseTooLargeError.new(
                "M_TOO_LARGE",
                "Response Content-Length #{body.length} bytes exceeds limit of #{limit} bytes",
              )
            end
            buffer = String.new(encoding: Encoding::BINARY)
            body.each do |chunk|
              buffer << chunk
              if buffer.bytesize > limit
                body.close
                raise ResponseTooLargeError.new(
                  "M_TOO_LARGE",
                  "Response body exceeds limit of #{limit} bytes",
                )
              end
            end
            buffer.empty? ? nil : buffer
          else
            nil
          end
        end

      # ── Retry logic ─────────────────────────────────────────────

      # Whether the given HTTP status code should trigger a retry.
      # 429 is only retried if @ignore_rate_limit is false.
      # 502/503/504 are always retried.
        def retryable_status?(status)
          if status == RATE_LIMIT_STATUS
            !@ignore_rate_limit
          else
            GATEWAY_ERROR_STATUSES.include?(status)
          end
        end

      # Compute the delay before the next retry attempt.
      #
      # For 429 (rate-limited): use the server's Retry-After header if present,
      # falling back to exponential backoff. The value is capped but not jittered
      # — the server is telling us exactly when to come back.
      #
      # For 502/503/504 (gateway errors): exponential backoff with full jitter.
      # Full jitter means rand(0..calculated), which is the AWS-recommended
      # approach to avoid thundering herd on shared homeservers.
        def compute_retry_delay(status, response, attempt)
          if status == RATE_LIMIT_STATUS
            server_delay = parse_retry_after(response)
            delay = server_delay || exponential_delay(attempt)
            [delay, @max_retry_delay].min
          else
            calculated = exponential_delay(attempt)
            rand(0.0..[calculated, @max_retry_delay].min)
          end
        end

      # Base * 2^(attempt-1): 0.5, 1.0, 2.0, 4.0, ...
        def exponential_delay(attempt)
          @retry_base_delay * (2 ** (attempt - 1))
        end

      # Parse the Retry-After header. Supports both delta-seconds ("120")
      # and HTTP-date ("Fri, 31 Dec 2026 23:59:59 GMT") formats per RFC 9110.
      # Returns seconds to wait as a Float, or nil if absent/unparseable.
        def parse_retry_after(response)
          value = response.headers["retry-after"]
          if value
            value = value.strip
            if value.match?(/\A\d+\z/)
              value.to_f
            else
              # HTTP-date format
              begin
                target = Time.httpdate(value)
                delay = target - Time.now
                delay > 0 ? delay : 0.0
              rescue ArgumentError
                nil
              end
            end
          else
            nil
          end
        end

        def encode(value)
          ERB::Util.url_encode(value)
        end

        public :request
    end
  end
end

__END__
  describe "Async::Matrix::Client" do
    def make_config
      Async::Matrix::Config.new({
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

    it "responds to media methods" do
      client = Async::Matrix::Client.new(make_config)
      client.should.respond_to :media
      client.should.respond_to :media_client
    end

    it "returns a MediaClient from media_client" do
      client = Async::Matrix::Client.new(make_config)
      client.media_client.should.be.kind_of Async::Matrix::MediaClient
    end

    it "returns a Gateway from media with media prefix" do
      client = Async::Matrix::Client.new(make_config)
      client.media.inspect.should.include "/_matrix/media/v3"
    end

    it "can be closed without error" do
      client = Async::Matrix::Client.new(make_config)
      client.media_client # force lazy init
      lambda { client.close }.should.not.raise
    end

    it "has retry defaults" do
      Async::Matrix::Client::DEFAULT_MAX_RETRIES.should == 3
      Async::Matrix::Client::DEFAULT_RETRY_BASE.should == 0.5
      Async::Matrix::Client::DEFAULT_MAX_RETRY_DELAY.should == 30
      Async::Matrix::Client::RATE_LIMIT_STATUS.should == 429
      Async::Matrix::Client::GATEWAY_ERROR_STATUSES.should == [502, 503, 504]
    end

    it "has response size limit defaults" do
      Async::Matrix::Client::DEFAULT_RESPONSE_SIZE_LIMIT.should == 50 * 1024 * 1024
      Async::Matrix::Client::DEFAULT_ERROR_RESPONSE_SIZE_LIMIT.should == 512 * 1024
    end

    it "accepts custom retry configuration" do
      client = Async::Matrix::Client.new(make_config, max_retries: 5, retry_base_delay: 1.0, max_retry_delay: 60)
      client.config.appservice.as_token.should == "test_token"
    end

    it "accepts max_retries: 0 to disable retries" do
      client = Async::Matrix::Client.new(make_config, max_retries: 0)
      client.config.appservice.as_token.should == "test_token"
    end

    it "accepts ignore_rate_limit option" do
      client = Async::Matrix::Client.new(make_config, ignore_rate_limit: true)
      client.config.appservice.as_token.should == "test_token"
    end

    it "accepts custom response size limits" do
      client = Async::Matrix::Client.new(make_config, response_size_limit: 1024, error_response_size_limit: 256)
      client.config.appservice.as_token.should == "test_token"
    end
  end

  # ── Shared test infrastructure ─────────────────────────────────────
  #
  # FakeBody and FakeResponse simulate async-http responses for testing.
  # FakeInternet replaces Async::HTTP::Internet to avoid network calls.

  # Simulates a response body that supports .each (streaming), .length,
  # and .close — matching the Protocol::HTTP::Body interface.
  FakeBody = Struct.new(:data, :content_length, :closed) do
    def initialize(data, content_length: nil)
      super(data, content_length, false)
    end

    def each(&block)
      data.each_char.each_slice(64) { |chars| block.call(chars.join) } if data
    end

    def length
      content_length
    end

    def close
      self.closed = true
    end
  end

  # Minimal response stub with status, body, and optional headers.
  FakeResponse = Struct.new(:status, :body, :header_hash) do
    def headers
      header_hash || {}
    end

    def close
      body&.close
    end
  end

  # A controllable replacement for Async::HTTP::Internet.
  FakeInternet = Struct.new(:responses, :call_count) do
    def initialize(responses)
      super(responses, 0)
    end

    def call(method, url, headers, body_data)
      resp = responses[call_count] || responses.last
      self.call_count += 1
      resp
    end

    def close; end
  end

  # ── Retry behaviour ───────────────────────────────────────────────

  describe "Client retry logic" do
    def make_config
      Async::Matrix::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "test_token", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    def make_client_with_responses(responses, max_retries: 3, retry_base_delay: 0.01,
                                   max_retry_delay: 1.0, ignore_rate_limit: false,
                                   response_size_limit: 50 * 1024 * 1024,
                                   error_response_size_limit: 512 * 1024)
      client = Async::Matrix::Client.new(
        make_config,
        max_retries: max_retries,
        retry_base_delay: retry_base_delay,
        max_retry_delay: max_retry_delay,
        ignore_rate_limit: ignore_rate_limit,
        response_size_limit: response_size_limit,
        error_response_size_limit: error_response_size_limit
      )
      fake = FakeInternet.new(responses)
      client.instance_variable_set(:@internet, fake)
      client.define_singleton_method(:sleep) { |_n| }
      [client, fake]
    end

    def ok_response(body_str = '{"ok":true}')
      FakeResponse.new(200, FakeBody.new(body_str), {})
    end

    def error_response(status, body_str = '{"errcode":"M_UNKNOWN","error":"fail"}', headers = {})
      FakeResponse.new(status, FakeBody.new(body_str), headers)
    end

    # ── Basic retry tests ──────────────────────────────────────────

    it "returns immediately on 200" do
      client, fake = make_client_with_responses([ok_response])
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 1
    end

    it "retries on 429 and succeeds" do
      client, fake = make_client_with_responses([error_response(429), ok_response])
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "retries on 502 and succeeds" do
      client, fake = make_client_with_responses([error_response(502, "Bad Gateway"), ok_response])
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "retries on 503 and succeeds" do
      client, fake = make_client_with_responses([error_response(503), ok_response])
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "retries on 504 and succeeds" do
      client, fake = make_client_with_responses([error_response(504), ok_response])
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "retries up to max_retries times then raises" do
      client, fake = make_client_with_responses(
        [error_response(502, "Bad Gateway")] * 4, max_retries: 3
      )
      lambda {
        client.get("/_matrix/client/v3/account/whoami")
      }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 4
    end

    it "does not retry on 400" do
      client, fake = make_client_with_responses([error_response(400)])
      lambda { client.get("/_matrix/client/v3/account/whoami") }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "does not retry on 403" do
      client, fake = make_client_with_responses([error_response(403)])
      lambda { client.get("/_matrix/client/v3/account/whoami") }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "does not retry on 404" do
      client, fake = make_client_with_responses([error_response(404)])
      lambda { client.get("/_matrix/client/v3/account/whoami") }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "does not retry on 500" do
      client, fake = make_client_with_responses([error_response(500)])
      lambda { client.get("/_matrix/client/v3/account/whoami") }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "does not retry when max_retries is 0" do
      client, fake = make_client_with_responses([error_response(429), ok_response], max_retries: 0)
      lambda { client.get("/_matrix/client/v3/account/whoami") }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "retries POST on 429" do
      client, fake = make_client_with_responses([error_response(429), ok_response])
      result = client.post("/_matrix/client/v3/createRoom", {name: "test"})
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "retries POST on 502" do
      client, fake = make_client_with_responses([error_response(502, "Bad Gateway"), ok_response])
      result = client.post("/_matrix/client/v3/createRoom", {name: "test"})
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "recovers after multiple retries" do
      client, fake = make_client_with_responses([
        error_response(503), error_response(503), error_response(503),
        ok_response('{"recovered":true}')
      ], max_retries: 3)
      result = client.get("/_matrix/client/v3/account/whoami")
      result["recovered"].should == true
      fake.call_count.should == 4
    end

    it "raises HomeserverError with correct status after exhausting retries" do
      client, _fake = make_client_with_responses([error_response(429)] * 4, max_retries: 3)
      begin
        client.get("/_matrix/client/v3/account/whoami")
        raise "should have raised"
      rescue Async::Matrix::HomeserverError => e
        e.status.should == 429
        e.errcode.should == "M_UNKNOWN"
      end
    end

    # ── Retry-After header parsing ──────────────────────────────────

    it "respects Retry-After header with delta-seconds" do
      delays = []
      client, _fake = make_client_with_responses([
        error_response(429, '{"errcode":"M_LIMIT_EXCEEDED","error":"rate limited"}', {"retry-after" => "2"}),
        ok_response
      ], max_retry_delay: 30.0)
      client.define_singleton_method(:sleep) { |n| delays << n }
      client.get("/_matrix/client/v3/account/whoami")
      delays.length.should == 1
      delays.first.should == 2.0
    end

    it "caps Retry-After at max_retry_delay" do
      delays = []
      client, _fake = make_client_with_responses([
        error_response(429, '{"errcode":"M_LIMIT_EXCEEDED","error":"rate limited"}', {"retry-after" => "9999"}),
        ok_response
      ], max_retry_delay: 5.0)
      client.define_singleton_method(:sleep) { |n| delays << n }
      client.get("/_matrix/client/v3/account/whoami")
      delays.first.should == 5.0
    end

    it "falls back to exponential backoff when Retry-After is absent on 429" do
      delays = []
      client, _fake = make_client_with_responses([error_response(429), ok_response], retry_base_delay: 0.25)
      client.define_singleton_method(:sleep) { |n| delays << n }
      client.get("/_matrix/client/v3/account/whoami")
      delays.length.should == 1
      delays.first.should == 0.25
    end

    it "uses jittered backoff for 502/503/504 (delay within expected range)" do
      delays = []
      client, _fake = make_client_with_responses([
        error_response(502, "Bad Gateway"), ok_response
      ], retry_base_delay: 1.0, max_retry_delay: 10.0)
      client.define_singleton_method(:sleep) { |n| delays << n }
      client.get("/_matrix/client/v3/account/whoami")
      delays.length.should == 1
      (delays.first >= 0.0).should == true
      (delays.first <= 1.0).should == true
    end

    # ── Unit tests for helpers ──────────────────────────────────────

    it "exponential_delay doubles each attempt" do
      client = Async::Matrix::Client.new(make_config, retry_base_delay: 0.5)
      client.send(:exponential_delay, 1).should == 0.5
      client.send(:exponential_delay, 2).should == 1.0
      client.send(:exponential_delay, 3).should == 2.0
      client.send(:exponential_delay, 4).should == 4.0
    end

    it "parse_retry_after returns nil when header is absent" do
      client = Async::Matrix::Client.new(make_config)
      resp = FakeResponse.new(429, nil, {})
      client.send(:parse_retry_after, resp).should.be.nil
    end

    it "parse_retry_after parses integer seconds" do
      client = Async::Matrix::Client.new(make_config)
      resp = FakeResponse.new(429, nil, {"retry-after" => "120"})
      client.send(:parse_retry_after, resp).should == 120.0
    end

    it "parse_retry_after returns nil for garbage" do
      client = Async::Matrix::Client.new(make_config)
      resp = FakeResponse.new(429, nil, {"retry-after" => "not-a-date"})
      client.send(:parse_retry_after, resp).should.be.nil
    end
  end

  # ── ignore_rate_limit ────────────────────────────────────────────

  describe "Client ignore_rate_limit" do
    def make_config
      Async::Matrix::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "test_token", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    def make_client_with_responses(responses, **opts)
      client = Async::Matrix::Client.new(make_config, **opts)
      fake = FakeInternet.new(responses)
      client.instance_variable_set(:@internet, fake)
      client.define_singleton_method(:sleep) { |_n| }
      [client, fake]
    end

    def ok_response(body_str = '{"ok":true}')
      FakeResponse.new(200, FakeBody.new(body_str), {})
    end

    def error_response(status, body_str = '{"errcode":"M_UNKNOWN","error":"fail"}', headers = {})
      FakeResponse.new(status, FakeBody.new(body_str), headers)
    end

    it "does not retry 429 when ignore_rate_limit is true" do
      client, fake = make_client_with_responses(
        [error_response(429), ok_response],
        ignore_rate_limit: true, max_retries: 3
      )
      lambda {
        client.get("/_matrix/client/v3/account/whoami")
      }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "still retries 502 when ignore_rate_limit is true" do
      client, fake = make_client_with_responses(
        [error_response(502, "Bad Gateway"), ok_response],
        ignore_rate_limit: true, max_retries: 3, retry_base_delay: 0.01
      )
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "still retries 503 when ignore_rate_limit is true" do
      client, fake = make_client_with_responses(
        [error_response(503), ok_response],
        ignore_rate_limit: true, max_retries: 3, retry_base_delay: 0.01
      )
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "retries 429 normally when ignore_rate_limit is false (default)" do
      client, fake = make_client_with_responses(
        [error_response(429), ok_response],
        ignore_rate_limit: false, max_retries: 3, retry_base_delay: 0.01
      )
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 2
    end
  end

  # ── Per-request max_retries override ─────────────────────────────

  describe "Client per-request max_retries" do
    def make_config
      Async::Matrix::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "test_token", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    def make_client_with_responses(responses, **opts)
      client = Async::Matrix::Client.new(make_config, **opts)
      fake = FakeInternet.new(responses)
      client.instance_variable_set(:@internet, fake)
      client.define_singleton_method(:sleep) { |_n| }
      [client, fake]
    end

    def ok_response(body_str = '{"ok":true}')
      FakeResponse.new(200, FakeBody.new(body_str), {})
    end

    def error_response(status, body_str = '{"errcode":"M_UNKNOWN","error":"fail"}', headers = {})
      FakeResponse.new(status, FakeBody.new(body_str), headers)
    end

    it "per-request max_retries: 0 disables retries for that call" do
      client, fake = make_client_with_responses(
        [error_response(429), ok_response],
        max_retries: 3, retry_base_delay: 0.01
      )
      lambda {
        client.get("/_matrix/client/v3/account/whoami", max_retries: 0)
      }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "per-request max_retries: 1 allows exactly one retry" do
      client, fake = make_client_with_responses(
        [error_response(502, "Bad Gateway"), error_response(502, "Bad Gateway"), ok_response],
        max_retries: 3, retry_base_delay: 0.01
      )
      lambda {
        client.get("/_matrix/client/v3/account/whoami", max_retries: 1)
      }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 2 # 1 initial + 1 retry
    end

    it "per-request max_retries: 1 succeeds on second attempt" do
      client, fake = make_client_with_responses(
        [error_response(502, "Bad Gateway"), ok_response],
        max_retries: 3, retry_base_delay: 0.01
      )
      result = client.get("/_matrix/client/v3/account/whoami", max_retries: 1)
      result["ok"].should == true
      fake.call_count.should == 2
    end

    it "nil max_retries falls back to client default" do
      client, fake = make_client_with_responses(
        [error_response(503), error_response(503), ok_response],
        max_retries: 2, retry_base_delay: 0.01
      )
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
      fake.call_count.should == 3
    end

    it "per-request max_retries works on post" do
      client, fake = make_client_with_responses(
        [error_response(429), ok_response],
        max_retries: 3, retry_base_delay: 0.01
      )
      lambda {
        client.post("/_matrix/client/v3/createRoom", {name: "test"}, max_retries: 0)
      }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end

    it "per-request max_retries works on put" do
      client, fake = make_client_with_responses(
        [error_response(429), ok_response],
        max_retries: 3, retry_base_delay: 0.01
      )
      lambda {
        client.put("/_matrix/client/v3/some/path", {data: true}, max_retries: 0)
      }.should.raise(Async::Matrix::HomeserverError)
      fake.call_count.should == 1
    end
  end

  # ── Response size limiting ───────────────────────────────────────

  describe "Client response size limiting" do
    def make_config
      Async::Matrix::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "test_token", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    def make_client_with_responses(responses, **opts)
      client = Async::Matrix::Client.new(make_config, **opts)
      fake = FakeInternet.new(responses)
      client.instance_variable_set(:@internet, fake)
      client.define_singleton_method(:sleep) { |_n| }
      [client, fake]
    end

    it "accepts responses within the size limit" do
      body = '{"ok":true}'
      resp = FakeResponse.new(200, FakeBody.new(body), {})
      client, _fake = make_client_with_responses([resp], response_size_limit: 1024)
      result = client.get("/_matrix/client/v3/account/whoami")
      result["ok"].should == true
    end

    it "raises ResponseTooLargeError when response body exceeds limit (streaming)" do
      big_body = "x" * 200
      resp = FakeResponse.new(200, FakeBody.new(big_body), {})
      client, _fake = make_client_with_responses([resp], response_size_limit: 100)
      lambda {
        client.get("/_matrix/client/v3/account/whoami")
      }.should.raise(Async::Matrix::ResponseTooLargeError)
    end

    it "raises ResponseTooLargeError via Content-Length pre-check" do
      body = FakeBody.new("small", content_length: 999_999_999)
      resp = FakeResponse.new(200, body, {})
      client, _fake = make_client_with_responses([resp], response_size_limit: 1024)
      lambda {
        client.get("/_matrix/client/v3/account/whoami")
      }.should.raise(Async::Matrix::ResponseTooLargeError)
    end

    it "closes the body on Content-Length rejection" do
      body = FakeBody.new("small", content_length: 999_999_999)
      resp = FakeResponse.new(200, body, {})
      client, _fake = make_client_with_responses([resp], response_size_limit: 1024)
      begin
        client.get("/_matrix/client/v3/account/whoami")
      rescue Async::Matrix::ResponseTooLargeError
      end
      body.closed.should == true
    end

    it "enforces error_response_size_limit on error responses" do
      big_error = "e" * 2000
      resp = FakeResponse.new(400, FakeBody.new(big_error), {})
      client, _fake = make_client_with_responses([resp], error_response_size_limit: 100)
      lambda {
        client.get("/_matrix/client/v3/account/whoami")
      }.should.raise(Async::Matrix::ResponseTooLargeError)
    end

    it "allows error responses within the error size limit" do
      error_body = '{"errcode":"M_UNKNOWN","error":"fail"}'
      resp = FakeResponse.new(400, FakeBody.new(error_body), {})
      client, _fake = make_client_with_responses([resp], error_response_size_limit: 1024)
      lambda {
        client.get("/_matrix/client/v3/account/whoami")
      }.should.raise(Async::Matrix::HomeserverError)
    end

    it "handles nil body gracefully" do
      resp = FakeResponse.new(200, nil, {})
      client, _fake = make_client_with_responses([resp], response_size_limit: 1024)
      result = client.get("/_matrix/client/v3/account/whoami")
      result.should == {}
    end

    it "read_limited returns nil for empty body" do
      body = FakeBody.new("")
      resp = FakeResponse.new(200, body, {})
      client = Async::Matrix::Client.new(make_config)
      result = client.send(:read_limited, resp, 1024)
      result.should.be.nil
    end
  end
