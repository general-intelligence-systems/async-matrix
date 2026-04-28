# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/discord"
require "async/matrix"

module Async
  module Discord
    # Runtime-generated Discord HTTP API built from the official OpenAPI spec.
    #
    # Loads the OpenAPI 3.1.0 JSON file from data/discord-api-spec/openapi.json
    # at require-time and builds a PathTree trie of all valid endpoints. API calls
    # are constructed via method chains (reusing Async::Matrix::Api::Chain),
    # validated against the tree, and terminated by .get(), .post(), .put(),
    # .patch(), or .delete().
    #
    # Usage:
    #   client.api.channels("123456").messages.post(content: "hello")
    #   client.api.guilds("789").members.get(limit: 100)
    #   client.api.users("@me").get
    #
    module Api
      # The shared PathTree instance, loaded once from the bundled spec.
      def self.path_tree
        @path_tree ||= PathTree.load
      end

      # Reset the cached path tree (useful for testing or reloading).
      def self.reset!
        @path_tree = nil
      end

      # Gateway produces Chain instances bound to a specific Discord Client.
      # Each call to a method on the Gateway starts a new chain.
      class Gateway
        def initialize(client, prefix: %w[api v10])
          @client = client
          @prefix = prefix
        end

        # Start a fresh chain. Every method call on the gateway creates
        # a new chain so chains are never reused.
        def chain
          Async::Matrix::Api::Chain.new(
            client: @client,
            path_tree: Api.path_tree,
            prefix: @prefix
          )
        end

        # Forward all unknown methods to a fresh chain, starting the path.
        def method_missing(name, *args, **kwargs, &block)
          if name.start_with?("to_")
            super
          else
            chain.__send__(name, *args, **kwargs, &block)
          end
        end

        def respond_to_missing?(name, include_private = false)
          !name.start_with?("to_") || super
        end

        def inspect
          "#<#{self.class} prefix=/#{@prefix.join("/")}>"
        end
      end
    end
  end
end

test do
  describe "Async::Discord::Api::Gateway" do
    # Stub client that records calls instead of making HTTP requests.
    StubDiscordClient = Struct.new(:calls) do
      def initialize
        super([])
      end

      def get(path, max_retries: nil)
        calls << [:get, path, {max_retries: max_retries}]
        {"stub" => true}
      end

      def post(path, body = {}, max_retries: nil)
        calls << [:post, path, body, {max_retries: max_retries}]
        {"stub" => true}
      end

      def put(path, body = {}, max_retries: nil)
        calls << [:put, path, body, {max_retries: max_retries}]
        {"stub" => true}
      end

      def request(method, path, body = nil, max_retries: nil)
        calls << [method.downcase.to_sym, path, body, {max_retries: max_retries}]
        {"stub" => true}
      end

      # Chain checks for media_client on binary routes; Discord doesn't need it
      # but we provide a stub to avoid NoMethodError.
      def media_client
        nil
      end
    end

    def make_gateway
      client = StubDiscordClient.new
      gateway = Async::Discord::Api::Gateway.new(client)
      [gateway, client]
    end

    it "GET /users/@me" do
      gw, client = make_gateway
      gw.users("@me").get
      client.calls.last[0].should == :get
      client.calls.last[1].should == "/api/v10/users/%40me"
    end

    it "POST /channels/{id}/messages" do
      gw, client = make_gateway
      gw.channels("123456").messages.post(content: "hello world")
      client.calls.last[0].should == :post
      client.calls.last[1].should == "/api/v10/channels/123456/messages"
      client.calls.last[2].should == {content: "hello world"}
    end

    it "GET /guilds/{id}/channels" do
      gw, client = make_gateway
      gw.guilds("789").channels.get
      client.calls.last[0].should == :get
      client.calls.last[1].should == "/api/v10/guilds/789/channels"
    end

    it "PATCH /channels/{id} via request" do
      gw, client = make_gateway
      gw.channels("123456").patch(name: "new-name")
      client.calls.last[0].should == :patch
    end

    it "each gateway method call starts a fresh chain" do
      gw, client = make_gateway
      gw.users("@me").get
      gw.channels("123").messages.post(content: "hi")
      client.calls.length.should == 2
    end

    it "raises InvalidEndpointError for unknown path" do
      gw, _ = make_gateway
      lambda { gw.totally.bogus.endpoint.get }.should.raise Async::Matrix::InvalidEndpointError
    end
  end
end
