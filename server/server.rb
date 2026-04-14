# frozen_string_literal: true

require "json"
require "rack"

module EchoBot
  # Rack 3 application implementing the Matrix Application Service API.
  #
  # Routes:
  #   PUT  /_matrix/app/v1/transactions/{txnId}  — receive events from homeserver
  #   GET  /_matrix/app/v1/users/{userId}         — user existence query
  #   GET  /_matrix/app/v1/rooms/{roomAlias}       — room alias query
  #   POST /_matrix/app/v1/ping                    — healthcheck
  class Server
    CONTENT_JSON = { "content-type" => "application/json" }.freeze
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
      token = extract_token(request)
      return false unless token
      secure_compare(token, @hs_token)
    end

    def extract_token(request)
      auth = request.get_header("HTTP_AUTHORIZATION")
      if auth && auth.start_with?("Bearer ")
        return auth.delete_prefix("Bearer ")
      end
      request.params["access_token"]
    end

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize
      l = a.unpack("C*")
      r = b.unpack("C*")
      result = 0
      l.each_with_index { |byte, i| result |= byte ^ r[i] }
      result.zero?
    end

    def handle_transaction(request, txn_id)
      if @txn_store.seen?(txn_id)
        Matrix.logger.debug { "Duplicate transaction #{txn_id} — skipping" }
        return [200, CONTENT_JSON, EMPTY_BODY]
      end

      body = parse_json(request)
      return RESP_BAD_JSON unless body

      Matrix.logger.info {
        event_count = (body["events"] || []).size
        "Transaction #{txn_id}: #{event_count} event(s)"
      }

      @dispatcher.dispatch_transaction(body)
      @txn_store.mark_seen(txn_id)

      [200, CONTENT_JSON, EMPTY_BODY]
    end

    def parse_json(request)
      raw = request.body&.read
      return nil if raw.nil? || raw.empty?
      JSON.parse(raw)
    rescue JSON::ParserError => e
      Matrix.logger.error { "Bad JSON in transaction: #{e.message}" }
      nil
    end
  end
end
