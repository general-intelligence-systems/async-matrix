# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    # Runtime-generated Matrix Client-Server API built from official OpenAPI schemas.
    #
    # Loads the OpenAPI 3.1.0 YAML files from data/matrix-spec/api/client-server/
    # at require-time and builds a PathTree trie of all valid endpoints. API calls
    # are constructed via StringBuilder method chains, validated against the tree,
    # and terminated by .get(), .post(), .put(), or .delete().
    #
    # Usage:
    #   # Via Client:
    #   client.api.account.whoami.get
    #   client.api.createRoom.post(name: "Pub", preset: "public_chat")
    #   client.api.rooms("!room:ex.com").ban.post(user_id: "@bad:ex.com")
    #   client.api.rooms("!room:ex.com").messages.get(dir: "b", limit: 10)
    #
    #   # Standalone (for inspection):
    #   gateway = Async::Matrix::Api::Gateway.new(client)
    #   chain = gateway.chain
    #   chain.rooms("!room:ex.com").state("m.room.name", "").get
    #
    module Api
      # The shared PathTree instance, loaded once from the bundled schemas.
      def self.path_tree
        @path_tree ||= PathTree.load
      end

      # Reset the cached path tree (useful for testing or reloading schemas).
      def self.reset!
        @path_tree = nil
      end

      # Gateway produces Chain instances bound to a specific Client.
      # Each call to a method on the Gateway starts a new chain.
      class Gateway
        def initialize(client, prefix: %w[_matrix client v3])
          @client  = client
          @prefix  = prefix
        end

        # Start a fresh chain. Every method call on the gateway creates
        # a new chain so chains are never reused.
        def chain
          Chain.new(client: @client, path_tree: Api.path_tree, prefix: @prefix)
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

__END__
  describe "Async::Matrix::Api::Gateway" do
    # Stub client that records calls instead of making HTTP requests.
    StubClient = Struct.new(:calls) do
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
    end

    def make_gateway
      client = StubClient.new
      # Build a small tree manually for deterministic tests
      tree = Async::Matrix::Api::PathTree.new
      tree.insert(%w[_matrix client v3 account whoami], "get")
      tree.insert(%w[_matrix client v3 createRoom], "post")
      tree.insert(%w[_matrix client v3 rooms {roomId} ban], "post")
      tree.insert(%w[_matrix client v3 rooms {roomId} messages], "get")
      tree.insert(%w[_matrix client v3 rooms {roomId} send {eventType} {txnId}], "put")
      tree.insert(%w[_matrix client v3 profile {userId} displayname], "put")
      tree.insert(%w[_matrix client v3 join {roomIdOrAlias}], "post")
      tree.insert(%w[_matrix client v3 rooms {roomId} leave], "post")

      # Inject our test tree
      Async::Matrix::Api.instance_variable_set(:@path_tree, tree)

      gateway = Async::Matrix::Api::Gateway.new(client)
      [gateway, client]
    end

    it "GET /account/whoami" do
      gw, client = make_gateway
      gw.account.whoami.get
      client.calls.last[0].should == :get
      client.calls.last[1].should == "/_matrix/client/v3/account/whoami"
    end

    it "POST /createRoom with body" do
      gw, client = make_gateway
      gw.createRoom.post(name: "Pub", preset: "public_chat")
      client.calls.last[0].should == :post
      client.calls.last[1].should == "/_matrix/client/v3/createRoom"
      client.calls.last[2].should == {name: "Pub", preset: "public_chat"}
    end

    it "POST /rooms/{roomId}/ban with body" do
      gw, client = make_gateway
      gw.rooms("!abc:ex.com").ban.post(user_id: "@bad:ex.com", reason: "spam")
      client.calls.last[0].should == :post
      client.calls.last[1].should == "/_matrix/client/v3/rooms/%21abc%3Aex.com/ban"
      client.calls.last[2].should == {user_id: "@bad:ex.com", reason: "spam"}
    end

    it "GET /rooms/{roomId}/messages with query params" do
      gw, client = make_gateway
      gw.rooms("!abc:ex.com").messages.get(dir: "b", limit: 10)
      call = client.calls.last
      call[0].should == :get
      call[1].should.include "/_matrix/client/v3/rooms/%21abc%3Aex.com/messages?"
      call[1].should.include "dir=b"
      call[1].should.include "limit=10"
    end

    it "PUT /rooms/{roomId}/send/{eventType}/{txnId}" do
      gw, client = make_gateway
      gw.rooms("!abc:ex.com").send("m.room.message", "txn-1").put(msgtype: "m.text", body: "hi")
      call = client.calls.last
      call[0].should == :put
      call[1].should == "/_matrix/client/v3/rooms/%21abc%3Aex.com/send/m.room.message/txn-1"
      call[2].should == {msgtype: "m.text", body: "hi"}
    end

    it "PUT /profile/{userId}/displayname" do
      gw, client = make_gateway
      gw.profile("@user:ex.com").displayname.put(displayname: "Bob")
      call = client.calls.last
      call[0].should == :put
      call[1].should == "/_matrix/client/v3/profile/%40user%3Aex.com/displayname"
      call[2].should == {displayname: "Bob"}
    end

    it "POST /join/{roomIdOrAlias}" do
      gw, client = make_gateway
      gw.join("!abc:ex.com").post
      call = client.calls.last
      call[0].should == :post
      call[1].should == "/_matrix/client/v3/join/%21abc%3Aex.com"
    end

    it "raises InvalidEndpointError for unknown path" do
      gw, _ = make_gateway
      lambda { gw.totally.bogus.endpoint.get }.should.raise Async::Matrix::InvalidEndpointError
    end

    it "raises InvalidEndpointError for wrong method" do
      gw, _ = make_gateway
      lambda { gw.account.whoami.post }.should.raise Async::Matrix::InvalidEndpointError
    end

    it "each gateway method call starts a fresh chain" do
      gw, client = make_gateway
      gw.account.whoami.get
      gw.createRoom.post(name: "test")
      client.calls.length.should == 2
      client.calls[0][1].should == "/_matrix/client/v3/account/whoami"
      client.calls[1][1].should == "/_matrix/client/v3/createRoom"
    end
  end
