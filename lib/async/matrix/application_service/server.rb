# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "json"
require "rack"
require "console"
require "async/matrix"

module Async
  module Matrix
    module ApplicationService
      # Rack 3 application implementing the Matrix Application Service API.
      #
      # Routes:
      #   PUT  /_matrix/app/v1/transactions/{txnId}  — receive events from homeserver
      #   GET  /_matrix/app/v1/users/{userId}         — user existence query
      #   GET  /_matrix/app/v1/rooms/{roomAlias}       — room alias query
      #   POST /_matrix/app/v1/ping                    — healthcheck
      class Server
        CONTENT_JSON = {"content-type" => "application/json"}.freeze
        EMPTY_BODY   = ["{}"].freeze

        RESP_NOT_FOUND  = [404, CONTENT_JSON, ['{"errcode":"M_UNRECOGNIZED"}']].freeze
        RESP_FORBIDDEN  = [403, CONTENT_JSON, ['{"errcode":"M_FORBIDDEN"}']].freeze
        RESP_BAD_JSON   = [400, CONTENT_JSON, ['{"errcode":"M_BAD_JSON"}']].freeze
        RESP_BAD_METHOD = [405, CONTENT_JSON, ['{"errcode":"M_UNRECOGNIZED"}']].freeze

        def initialize(hs_token:, dispatcher:)
          @hs_token   = hs_token
          @dispatcher = dispatcher
          @txn_store  = TransactionStore.new
        end

        def call(env)
          request = Rack::Request.new(env)
          method  = request.request_method
          path    = request.path_info

          case path
          when %r{\A/_matrix/app/v1/transactions/(.+)\z}
            return RESP_BAD_METHOD unless method == "PUT"
            return RESP_FORBIDDEN  unless authorized?(request)
            handle_transaction(request, Regexp.last_match(1))

          when %r{\A/_matrix/app/v1/users/(.+)\z}
            return RESP_BAD_METHOD unless method == "GET"
            return RESP_FORBIDDEN  unless authorized?(request)
            [200, CONTENT_JSON, EMPTY_BODY]

          when %r{\A/_matrix/app/v1/rooms/(.+)\z}
            return RESP_BAD_METHOD unless method == "GET"
            return RESP_FORBIDDEN  unless authorized?(request)
            RESP_NOT_FOUND

          when "/_matrix/app/v1/ping"
            return RESP_BAD_METHOD unless method == "POST"
            [200, CONTENT_JSON, EMPTY_BODY]

          else
            RESP_NOT_FOUND
          end
        end

        private

          def authorized?(request)
            extract_token(request).then do |token|
              if token
                secure_compare(token, @hs_token)
              else
                false
              end
            end
          end

          def extract_token(request)
            auth = request.get_header("HTTP_AUTHORIZATION")
            if auth && auth.start_with?("Bearer ")
              auth.delete_prefix("Bearer ")
            else
              request.params["access_token"]
            end
          end

          def secure_compare(a, b)
            if a.bytesize == b.bytesize
              l = a.unpack("C*")
              r = b.unpack("C*")
              result = 0
              l.each_with_index { |byte, i| result |= byte ^ r[i] }
              result.zero?
            else
              false
            end
          end

          def handle_transaction(request, txn_id)
            if @txn_store.seen?(txn_id)
              Console.debug(self) { "Duplicate transaction #{txn_id} — skipping" }
              [200, CONTENT_JSON, EMPTY_BODY]
            else
              body = parse_json(request)

              if body
                Console.info(self) {
                  event_count = (body["events"] || []).size
                  "Transaction #{txn_id}: #{event_count} event(s)"
                }

                @dispatcher.dispatch_transaction(body)
                @txn_store.mark_seen(txn_id)

                [200, CONTENT_JSON, EMPTY_BODY]
              else
                RESP_BAD_JSON
              end
            end
          end

          def parse_json(request)
            raw = request.body&.read

            if raw.nil? || raw.empty?
              nil
            else
              JSON.parse(raw)
            end
          rescue JSON::ParserError => e
            Console.error(self) { "Bad JSON in transaction: #{e.message}" }
            nil
          end
      end
    end
  end
end

test do
  require "stringio"

  describe "Async::Matrix::ApplicationService::Server" do
    def build_server(hs_token: "secret")
      dispatcher = Async::Matrix::ApplicationService::Dispatcher.new
      Async::Matrix::ApplicationService::Server.new(hs_token: hs_token, dispatcher: dispatcher)
    end

    def env(method, path, headers: {}, body: nil, params: {})
      rack_env = {
        "REQUEST_METHOD" => method,
        "PATH_INFO" => path,
        "QUERY_STRING" => params.map { |k, v| "#{k}=#{v}" }.join("&"),
        "rack.input" => body ? StringIO.new(body) : StringIO.new("")
      }
      headers.each { |k, v| rack_env["HTTP_#{k.upcase.tr("-", "_")}"] = v }
      rack_env
    end

    # --- Ping ---

    it "responds to POST /ping with 200" do
      server = build_server
      status, _, _ = server.call(env("POST", "/_matrix/app/v1/ping"))
      status.should == 200
    end

    it "rejects GET /ping with 405" do
      server = build_server
      status, _, _ = server.call(env("GET", "/_matrix/app/v1/ping"))
      status.should == 405
    end

    # --- Auth ---

    it "rejects transactions without a token" do
      server = build_server
      status, _, _ = server.call(env("PUT", "/_matrix/app/v1/transactions/txn1"))
      status.should == 403
    end

    it "rejects transactions with wrong token" do
      server = build_server(hs_token: "correct")
      status, _, _ = server.call(env("PUT", "/_matrix/app/v1/transactions/txn1",
        headers: {"authorization" => "Bearer wrong"}))
      status.should == 403
    end

    # --- Transactions ---

    it "accepts valid transactions with Bearer auth" do
      server = build_server(hs_token: "secret")
      status, _, _ = server.call(env("PUT", "/_matrix/app/v1/transactions/txn1",
        headers: {"authorization" => "Bearer secret"},
        body: '{"events":[]}'))
      status.should == 200
    end

    it "deduplicates transactions" do
      server = build_server(hs_token: "secret")
      rack = env("PUT", "/_matrix/app/v1/transactions/txn1",
        headers: {"authorization" => "Bearer secret"},
        body: '{"events":[]}')
      server.call(rack)
      # Second call with same txn_id
      rack2 = env("PUT", "/_matrix/app/v1/transactions/txn1",
        headers: {"authorization" => "Bearer secret"},
        body: '{"events":[]}')
      status, _, _ = server.call(rack2)
      status.should == 200
    end

    it "rejects bad JSON" do
      server = build_server(hs_token: "secret")
      status, _, _ = server.call(env("PUT", "/_matrix/app/v1/transactions/txn1",
        headers: {"authorization" => "Bearer secret"},
        body: "not json"))
      status.should == 400
    end

    # --- Users / Rooms ---

    it "responds 200 for user queries" do
      server = build_server(hs_token: "secret")
      status, _, _ = server.call(env("GET", "/_matrix/app/v1/users/@bot:localhost",
        headers: {"authorization" => "Bearer secret"}))
      status.should == 200
    end

    it "responds 404 for room queries" do
      server = build_server(hs_token: "secret")
      status, _, _ = server.call(env("GET", "/_matrix/app/v1/rooms/#room:localhost",
        headers: {"authorization" => "Bearer secret"}))
      status.should == 404
    end

    # --- Unknown routes ---

    it "responds 404 for unknown paths" do
      server = build_server
      status, _, _ = server.call(env("GET", "/unknown"))
      status.should == 404
    end
  end
end
