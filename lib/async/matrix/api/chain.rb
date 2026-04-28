# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"
require "string_builder"
require "erb"

module Async
  module Matrix
    module Api
      # Wraps a StringBuilder to build Matrix API paths via method chaining,
      # terminated by .get(), .post(), .put(), or .delete() which validate
      # the path against the PathTree and fire the HTTP request.
      #
      # Inherits from BasicObject so that method names like `send`, `display`,
      # `format`, `test`, etc. are not defined and fall through to
      # method_missing, where they get recorded as URL path segments.
      #
      # Usage:
      #   chain = Chain.new(client: client, path_tree: tree, prefix: %w[_matrix client v3])
      #   chain.account.whoami.get
      #   chain.rooms("!abc:ex.com").send("m.room.message", "txn1").put(body: "hi")
      #   chain.rooms("!abc:ex.com").messages.get(dir: "b", limit: 10)
      #
      class Chain < ::BasicObject
        def initialize(client:, path_tree:, prefix: nil)
          @client    = client
          @path_tree = path_tree
          @prefix    = prefix || ["_matrix", "client", "v3"]
          @buffer    = []
        end

        # ── Terminal HTTP methods ──────────────────────────────────

        def get(**kwargs)
          execute("GET", query: kwargs)
        end

        def post(body = nil, **kwargs)
          execute("POST", body: body || kwargs)
        end

        def put(body = nil, **kwargs)
          execute("PUT", body: body || kwargs)
        end

        def delete(**kwargs)
          execute("DELETE", query: kwargs)
        end

        # ── Chain inspection ───────────────────────────────────────

        def to_s
          "/" + _build_full_segments.map { |s| _encode(s) }.join("/")
        end

        def inspect
          segments = _build_full_segments
          "#<Async::Matrix::Api::Chain path=/#{segments.join("/")}>"
        end

        def path_segments
          _build_full_segments
        end

        # ── Everything else becomes a path segment ─────────────────

        def method_missing(name, *args, **kwargs)
          if kwargs.empty?
            @buffer << [name.to_s, args]
          else
            @buffer << [name.to_s, [*args, kwargs]]
          end
          self
        end

        private

        def execute(method, body: nil, query: nil)
          segments = _build_full_segments
          result = @path_tree.match(segments, method)

          if !result[:valid]
            path = "/" + segments.join("/")
            available = result[:methods]
            if available.empty?
              ::Kernel.raise ::Async::Matrix::InvalidEndpointError.new(
                "INVALID_ENDPOINT",
                "No Matrix API endpoint matches: #{method} #{path}"
              )
            else
              ::Kernel.raise ::Async::Matrix::InvalidEndpointError.new(
                "METHOD_NOT_ALLOWED",
                "#{method} not allowed for #{path}. Valid methods: #{available.map(&:upcase).join(", ")}"
              )
            end
          end

          path = "/" + segments.map { |s| _encode(s) }.join("/")

          case method
          when "GET"
            if query && !query.empty?
              qs = query.map { |k, v| "#{_encode(k.to_s)}=#{_encode(v.to_s)}" }.join("&")
              path = "#{path}?#{qs}"
            end
            @client.get(path)
          when "POST"
            @client.post(path, body || {})
          when "PUT"
            @client.put(path, body || {})
          when "DELETE"
            @client.request("DELETE", path)
          end
        end

        def _build_full_segments
          chain_segments = []
          @buffer.each do |name, args|
            chain_segments << name
            next if args.nil? || args.empty?
            args.each do |arg|
              next if arg.is_a?(::Hash)
              chain_segments << arg.to_s
            end
          end
          @prefix + chain_segments
        end

        def _encode(value)
          ::ERB::Util.url_encode(value.to_s)
        end
      end
    end
  end
end

test do
  describe "Async::Matrix::Api::Chain" do
    def make_tree
      tree = Async::Matrix::Api::PathTree.new
      tree.insert(%w[_matrix client v3 account whoami], "get", "getAccountWhoami")
      tree.insert(%w[_matrix client v3 createRoom], "post", "createRoom")
      tree.insert(%w[_matrix client v3 rooms {roomId} ban], "post", "ban")
      tree.insert(%w[_matrix client v3 rooms {roomId} state {eventType} {stateKey}], "get")
      tree.insert(%w[_matrix client v3 rooms {roomId} state {eventType} {stateKey}], "put")
      tree.insert(%w[_matrix client v3 rooms {roomId} messages], "get", "getRoomMessages")
      tree.insert(%w[_matrix client v3 rooms {roomId} send {eventType} {txnId}], "put")
      tree.insert(%w[_matrix client v3 profile {userId} displayname], "put", "setDisplayName")
      tree
    end

    it "builds correct path segments for simple chain" do
      chain = Async::Matrix::Api::Chain.new(
        client: nil, path_tree: make_tree
      )
      chain.account.whoami
      chain.path_segments.should == %w[_matrix client v3 account whoami]
    end

    it "builds correct path segments with args" do
      chain = Async::Matrix::Api::Chain.new(
        client: nil, path_tree: make_tree
      )
      chain.rooms("!abc:ex.com").ban
      chain.path_segments.should == %w[_matrix client v3 rooms !abc:ex.com ban]
    end

    it "builds correct to_s with URL encoding" do
      chain = Async::Matrix::Api::Chain.new(
        client: nil, path_tree: make_tree
      )
      chain.rooms("!abc:ex.com").ban
      chain.to_s.should == "/_matrix/client/v3/rooms/%21abc%3Aex.com/ban"
    end

    it "builds path for /rooms/{roomId}/send/{eventType}/{txnId}" do
      chain = Async::Matrix::Api::Chain.new(
        client: nil, path_tree: make_tree
      )
      chain.rooms("!abc:ex.com").send("m.room.message", "txn-123")
      chain.path_segments.should == %w[_matrix client v3 rooms !abc:ex.com send m.room.message txn-123]
    end

    it "raises InvalidEndpointError for unknown path" do
      chain = Async::Matrix::Api::Chain.new(
        client: nil, path_tree: make_tree
      )
      chain.account.foobar
      lambda { chain.get }.should.raise Async::Matrix::InvalidEndpointError
    end

    it "raises InvalidEndpointError for wrong HTTP method" do
      chain = Async::Matrix::Api::Chain.new(
        client: nil, path_tree: make_tree
      )
      chain.account.whoami
      lambda { chain.post }.should.raise Async::Matrix::InvalidEndpointError
    end
  end
end
