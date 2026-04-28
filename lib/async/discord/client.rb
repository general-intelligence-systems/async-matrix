# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http/internet"
require "async/discord"
require "json"
require "erb"
require "console"
require "time"

module Async
  module Discord
    # Async HTTP client for the Discord REST API.
    #
    # Authenticated with a Bot token. All methods are fiber-safe and run
    # naturally inside Falcon's async reactor.
    #
    #   client = Async::Discord::Client.new(token: "MTk...")
    #   client.api.channels("123").messages.post(content: "hello")
    #   client.api.users("@me").get
    #
    class Client
      DEFAULT_BASE_URL = "https://discord.com"

      # Retry defaults
      DEFAULT_MAX_RETRIES     = 3
      DEFAULT_RETRY_BASE      = 0.5
      DEFAULT_MAX_RETRY_DELAY = 30

      # Status codes eligible for retry
      RATE_LIMIT_STATUS      = 429
      GATEWAY_ERROR_STATUSES = [502, 503, 504].freeze

      # Response size limits (bytes)
      DEFAULT_RESPONSE_SIZE_LIMIT       = 50 * 1024 * 1024   # 50 MiB
      DEFAULT_ERROR_RESPONSE_SIZE_LIMIT = 512 * 1024          # 512 KiB

      attr_reader :token

      def initialize(token:, base_url: DEFAULT_BASE_URL,
                     max_retries: DEFAULT_MAX_RETRIES,
                     retry_base_delay: DEFAULT_RETRY_BASE,
                     max_retry_delay: DEFAULT_MAX_RETRY_DELAY,
                     response_size_limit: DEFAULT_RESPONSE_SIZE_LIMIT,
                     error_response_size_limit: DEFAULT_ERROR_RESPONSE_SIZE_LIMIT)
        @token                     = token
        @base                      = base_url
        @max_retries               = max_retries
        @retry_base_delay          = retry_base_delay
        @max_retry_delay           = max_retry_delay
        @response_size_limit       = response_size_limit
        @error_response_size_limit = error_response_size_limit
        @headers = [
          ["authorization", "Bot #{token}"],
          ["content-type",  "application/json"],
          ["user-agent",    "AsyncDiscord (https://github.com/general-intelligence-systems/async-matrix, 1.0)"]
        ]
      end

      # ── Full API (runtime-generated from OpenAPI spec) ────────

      # Returns a Gateway that provides method-chained access to every
      # Discord HTTP API endpoint. Chains are validated against the official
      # OpenAPI path tree and terminated by .get(), .post(), .put(),
      # .patch(), or .delete().
      #
      #   client.api.channels("123").messages.post(content: "hello")
      #   client.api.guilds("789").get
      #   client.api.users("@me").get
      #
      def api
        Api::Gateway.new(self)
      end

      # ── Low-level HTTP ────────────────────────────────────────

      def get(path, max_retries: nil)
        request("GET", path, nil, max_retries: max_retries)
      end

      def post(path, body = {}, max_retries: nil)
        request("POST", path, body, max_retries: max_retries)
      end

      def put(path, body = {}, max_retries: nil)
        request("PUT", path, body, max_retries: max_retries)
      end

      def close
        @internet&.close
        @internet = nil
      end

      # General-purpose request method supporting any HTTP method.
      def request(method, path, body = nil, max_retries: nil)
        url = "#{@base}#{path}"
        json_body = body ? JSON.generate(body) : nil
        effective_max_retries = max_retries || @max_retries

        Console.debug(self) { "#{method} #{path}" }

        attempt = 0
        loop do
          response = internet.call(method, url, @headers, json_body)
          status   = response.status

          if (200..299).cover?(status)
            payload = read_limited(response, @response_size_limit)
            return payload && !payload.empty? ? JSON.parse(payload) : {}
          end

          attempt += 1

          if attempt <= effective_max_retries && retryable_status?(status)
            delay = compute_retry_delay(status, response, attempt)
            Console.warn(self) {
              "#{method} #{path} returned #{status}, retry #{attempt}/#{effective_max_retries} in #{delay.round(2)}s"
            }
            response.close if response.respond_to?(:close)
            sleep(delay)
            next
          end

          payload = read_limited(response, @error_response_size_limit)
          parsed = begin; JSON.parse(payload || "{}"); rescue; {} end
          discord_code = parsed["code"]
          discord_msg  = parsed["message"] || payload.to_s[0..200]

          Console.error(self) { "Discord API #{status}: #{discord_code} — #{discord_msg}" }

          error_class = case status
                        when 401 then AuthError
                        when 429 then RateLimitError
                        when 400..499 then ApiError
                        else ServerError
                        end

          raise error_class.new(
            discord_code.to_s,
            discord_msg,
            status: status
          )
        end
      end

      private

        def internet
          @internet ||= Async::HTTP::Internet.new
        end

        # ── Response size limiting ──────────────────────────────

        def read_limited(response, limit)
          body = response.body
          return nil unless body

          if body.respond_to?(:length) && body.length && body.length > limit
            body.close
            raise ResponseTooLargeError.new(
              "TOO_LARGE",
              "Response Content-Length #{body.length} bytes exceeds limit of #{limit} bytes"
            )
          end

          buffer = String.new(encoding: Encoding::BINARY)
          body.each do |chunk|
            buffer << chunk
            if buffer.bytesize > limit
              body.close
              raise ResponseTooLargeError.new(
                "TOO_LARGE",
                "Response body exceeds limit of #{limit} bytes"
              )
            end
          end
          buffer.empty? ? nil : buffer
        end

        # ── Retry logic ─────────────────────────────────────────

        def retryable_status?(status)
          status == RATE_LIMIT_STATUS || GATEWAY_ERROR_STATUSES.include?(status)
        end

        # Discord sends Retry-After as seconds (float) in the JSON body on 429,
        # and also as X-RateLimit-Reset-After header. We check both.
        def compute_retry_delay(status, response, attempt)
          if status == RATE_LIMIT_STATUS
            server_delay = parse_rate_limit_delay(response)
            delay = server_delay || exponential_delay(attempt)
            [delay, @max_retry_delay].min
          else
            calculated = exponential_delay(attempt)
            rand(0.0..[calculated, @max_retry_delay].min)
          end
        end

        def exponential_delay(attempt)
          @retry_base_delay * (2 ** (attempt - 1))
        end

        # Parse Discord rate limit delay. Checks:
        #   1. X-RateLimit-Reset-After header (seconds as float)
        #   2. Retry-After header (seconds as integer)
        def parse_rate_limit_delay(response)
          reset_after = response.headers["x-ratelimit-reset-after"]
          return reset_after.to_f if reset_after

          retry_after = response.headers["retry-after"]
          return retry_after.to_f if retry_after && retry_after.strip.match?(/\A[\d.]+\z/)

          nil
        end

        def encode(value)
          ERB::Util.url_encode(value)
        end
    end
  end
end

test do
  describe "Async::Discord::Client" do
    it "sets authorization header with Bot prefix" do
      client = Async::Discord::Client.new(token: "test_token_123")
      headers = client.instance_variable_get(:@headers)
      auth = headers.find { |k, _| k == "authorization" }
      auth[1].should == "Bot test_token_123"
    end

    it "stores the token" do
      client = Async::Discord::Client.new(token: "my_token")
      client.token.should == "my_token"
    end

    it "defaults base URL to discord.com" do
      client = Async::Discord::Client.new(token: "tok")
      client.instance_variable_get(:@base).should == "https://discord.com"
    end

    it "accepts custom base URL" do
      client = Async::Discord::Client.new(token: "tok", base_url: "http://localhost:9999")
      client.instance_variable_get(:@base).should == "http://localhost:9999"
    end

    it "responds to HTTP methods" do
      client = Async::Discord::Client.new(token: "tok")
      client.should.respond_to :get
      client.should.respond_to :post
      client.should.respond_to :put
      client.should.respond_to :request
      client.should.respond_to :close
    end

    it "responds to api" do
      client = Async::Discord::Client.new(token: "tok")
      client.should.respond_to :api
    end

    it "returns a Discord Api::Gateway from api" do
      client = Async::Discord::Client.new(token: "tok")
      client.api.should.be.kind_of Async::Discord::Api::Gateway
    end

    it "accepts custom retry configuration" do
      client = Async::Discord::Client.new(
        token: "tok",
        max_retries: 5,
        retry_base_delay: 1.0,
        max_retry_delay: 60
      )
      client.instance_variable_get(:@max_retries).should == 5
      client.instance_variable_get(:@retry_base_delay).should == 1.0
      client.instance_variable_get(:@max_retry_delay).should == 60
    end

    it "can be closed without error" do
      client = Async::Discord::Client.new(token: "tok")
      lambda { client.close }.should.not.raise
    end
  end
end
