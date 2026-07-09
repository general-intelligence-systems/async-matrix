# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

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
        # Paths that carry raw bytes instead of JSON. Matched by
        # _binary_route? where * is a single-segment wildcard.
        # The HTTP method determines the operation:
        #   GET  → download (returns raw bytes)
        #   POST/PUT → upload (sends raw bytes)
        BINARY_ROUTES = [
          "/_matrix/media/v3/upload",
          "/_matrix/media/v3/upload/*/*",
          "/_matrix/media/v3/download/*/*",
          "/_matrix/media/v3/download/*/*/*",
          "/_matrix/media/v3/thumbnail/*/*",
          "/_matrix/client/v1/media/download/*/*",
          "/_matrix/client/v1/media/download/*/*/*",
          "/_matrix/client/v1/media/thumbnail/*/*",
        ].freeze

        def initialize(client:, path_tree:, prefix: nil)
          @client    = client
          @path_tree = path_tree
          @prefix    = prefix || ["_matrix", "client", "v3"]
          @buffer    = []
        end

        # ── Terminal HTTP methods ──────────────────────────────────

        def get(**kwargs)
          max_retries = kwargs.delete(:max_retries)
          execute("GET", query: kwargs, max_retries: max_retries)
        end

        def post(body = nil, **kwargs)
          content_type = kwargs.delete(:content_type)
          max_retries  = kwargs.delete(:max_retries)
          query        = _extract_query_params(kwargs)
          execute("POST", body: body || kwargs, content_type: content_type, max_retries: max_retries, query: query)
        end

        def put(body = nil, **kwargs)
          content_type = kwargs.delete(:content_type)
          max_retries  = kwargs.delete(:max_retries)
          query        = _extract_query_params(kwargs)
          execute("PUT", body: body || kwargs, content_type: content_type, max_retries: max_retries, query: query)
        end

        def delete(**kwargs)
          max_retries = kwargs.delete(:max_retries)
          execute("DELETE", query: kwargs, max_retries: max_retries)
        end

        def patch(body = nil, **kwargs)
          content_type = kwargs.delete(:content_type)
          max_retries  = kwargs.delete(:max_retries)
          query        = _extract_query_params(kwargs)
          execute("PATCH", body: body || kwargs, content_type: content_type, max_retries: max_retries, query: query)
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

        def execute(method, body: nil, query: nil, content_type: nil, max_retries: nil)
          segments = _rewrite_version(_build_full_segments)
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

          if query && !query.empty?
            qs = query.map { |k, v| "#{_encode(k.to_s)}=#{_encode(v.to_s)}" }.join("&")
            path = "#{path}?#{qs}"
          end

          if _binary_route?(segments)
            case method
            when "GET"
              @client.media_client.download(path)
            when "POST"
              @client.media_client.upload("POST", path, body, content_type || "application/octet-stream")
            when "PUT"
              @client.media_client.upload("PUT", path, body, content_type || "application/octet-stream")
            end
          else
            retry_opts = max_retries ? {max_retries: max_retries} : {}
            case method
            when "GET"
              @client.get(path, **retry_opts)
            when "POST"
              @client.post(path, body || {}, **retry_opts)
            when "PUT"
              @client.put(path, body || {}, **retry_opts)
            when "DELETE"
              @client.request("DELETE", path, nil, **retry_opts)
            when "PATCH"
              @client.request("PATCH", path, body || {}, **retry_opts)
            end
          end
        end

        # Rewrites version segments for endpoints that only exist at
        # a different version than the gateway prefix provides.
        #   _matrix/media/v3/create        → _matrix/media/v1/create
        #   _matrix/client/v3/media/...    → _matrix/client/v1/media/...
        def _rewrite_version(segments)
          # POST /_matrix/media/v1/create (only exists at v1)
          if segments.length == 4 &&
             segments[0] == "_matrix" && segments[1] == "media" &&
             segments[2] == "v3" && segments[3] == "create"
            segments = segments.dup
            segments[2] = "v1"
            return segments
          end

          # Authenticated media endpoints live at /_matrix/client/v1/media/...
          if segments.length >= 5 &&
             segments[0] == "_matrix" && segments[1] == "client" &&
             segments[2] == "v3" && segments[3] == "media"
            segments = segments.dup
            segments[2] = "v1"
            return segments
          end

          segments
        end

        def _binary_route?(segments)
          BINARY_ROUTES.any? do |pattern|
            parts = pattern.split("/")
            next false unless parts.length == segments.length + 1 # leading slash adds empty element
            parts.shift # remove empty string from leading /
            parts.length == segments.length &&
              parts.zip(segments).all? { |pat, seg| pat == "*" || pat == seg }
          end
        end

        def _extract_query_params(kwargs)
          query = {}
          kwargs.each_key do |k|
            key_s = k.to_s
            if key_s.start_with?("?")
              query[key_s[1..]] = kwargs.delete(k)
            end
          end
          query.empty? ? nil : query
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

__END__
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

    # ── Binary route detection ───────────────────────────────

    def make_media_tree
      tree = Async::Matrix::Api::PathTree.new
      tree.insert(%w[_matrix media v3 upload], "post", "uploadContent")
      tree.insert(%w[_matrix media v3 upload {serverName} {mediaId}], "put", "uploadContentToMXC")
      tree.insert(%w[_matrix media v3 download {serverName} {mediaId}], "get", "getContent")
      tree.insert(%w[_matrix media v3 download {serverName} {mediaId} {fileName}], "get", "getContentOverrideName")
      tree.insert(%w[_matrix media v3 thumbnail {serverName} {mediaId}], "get", "getContentThumbnail")
      tree.insert(%w[_matrix client v1 media download {serverName} {mediaId}], "get", "getContentAuthed")
      tree.insert(%w[_matrix client v1 media download {serverName} {mediaId} {fileName}], "get", "getContentOverrideNameAuthed")
      tree.insert(%w[_matrix client v1 media thumbnail {serverName} {mediaId}], "get", "getContentThumbnailAuthed")
      tree
    end

    # Stub response object for download tests.
    StubResponse = Struct.new(:body_bytes, :headers, :status) do
      def initialize(body_bytes = "\xFF\xD8\xFF".b)
        super(body_bytes, {"content-type" => "image/jpeg"}, 200)
      end

      def read
        body_bytes
      end
    end

    # Stub client with a stub media_client for testing dispatch.
    StubMediaClient = Struct.new(:calls) do
      def initialize
        super([])
      end

      def upload(method, path, body, content_type)
        calls << [:upload, method, path, body, content_type]
        {"content_uri" => "mxc://example.com/abc123"}
      end

      def download(path)
        calls << [:download, path]
        StubResponse.new
      end
    end

    StubClientWithMedia = Struct.new(:calls, :media_client) do
      def initialize
        super([], StubMediaClient.new)
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

    it "detects upload route and dispatches to media_client" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      chain.upload.post("image-bytes", content_type: "image/png")
      client.media_client.calls.last[0].should == :upload
      client.media_client.calls.last[1].should == "POST"
      client.media_client.calls.last[3].should == "image-bytes"
      client.media_client.calls.last[4].should == "image/png"
      client.calls.should.be.empty
    end

    it "detects upload PUT route and dispatches to media_client" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      chain.upload("example.com", "abc123").put("image-bytes", content_type: "image/jpeg")
      client.media_client.calls.last[0].should == :upload
      client.media_client.calls.last[1].should == "PUT"
      client.media_client.calls.last[4].should == "image/jpeg"
      client.calls.should.be.empty
    end

    it "detects download route and dispatches to media_client" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      response = chain.download("example.com", "abc123").get
      client.media_client.calls.last[0].should == :download
      response.read.should == "\xFF\xD8\xFF".b
      response.headers["content-type"].should == "image/jpeg"
      client.calls.should.be.empty
    end

    it "detects download with filename route" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      chain.download("example.com", "abc123", "photo.jpg").get
      client.media_client.calls.last[0].should == :download
    end

    it "detects thumbnail route and passes query params" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      chain.thumbnail("example.com", "abc123").get(width: 64, height: 64)
      call = client.media_client.calls.last
      call[0].should == :download
      call[1].should.include "width=64"
      call[1].should.include "height=64"
    end

    it "detects authed download route (client/v1 prefix)" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix client v1]
      )
      chain.media.download("example.com", "abc123").get
      client.media_client.calls.last[0].should == :download
    end

    it "does NOT route non-binary paths to media_client" do
      client = StubClientWithMedia.new
      tree = make_tree
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: tree
      )
      chain.account.whoami.get
      client.calls.last[0].should == :get
      client.media_client.calls.should.be.empty
    end

    it "defaults content_type to application/octet-stream for uploads" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      chain.upload.post("raw-bytes")
      client.media_client.calls.last[4].should == "application/octet-stream"
    end

    # ── ?-prefixed query params on uploads ────────────────────

    it "passes ?-prefixed kwargs as query params on upload POST" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      chain.upload.post("image-bytes", content_type: "image/png", "?filename": "photo.png")
      call = client.media_client.calls.last
      call[0].should == :upload
      call[2].should.include "filename=photo.png"
      call[4].should == "image/png"
    end

    it "passes ?-prefixed kwargs as query params on upload PUT" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix media v3]
      )
      chain.upload("example.com", "abc123").put("bytes", content_type: "image/jpeg", "?filename": "pic.jpg")
      call = client.media_client.calls.last
      call[0].should == :upload
      call[2].should.include "filename=pic.jpg"
    end

    # ── Version rewrites ──────────────────────────────────────

    def make_full_media_tree
      tree = make_media_tree
      tree.insert(%w[_matrix media v1 create], "post", "createContent")
      tree.insert(%w[_matrix media v3 config], "get", "getConfig")
      tree.insert(%w[_matrix media v3 preview_url], "get", "getUrlPreview")
      tree
    end

    it "rewrites media/v3/create to media/v1/create" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_full_media_tree, prefix: %w[_matrix media v3]
      )
      chain.create.post
      call = client.calls.last
      call[0].should == :post
      call[1].should == "/_matrix/media/v1/create"
    end

    it "rewrites client/v3/media/download to client/v1/media/download" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix client v3]
      )
      chain.media.download("example.com", "abc123").get
      call = client.media_client.calls.last
      call[0].should == :download
      call[1].should.include "/_matrix/client/v1/media/download/"
    end

    it "rewrites client/v3/media/thumbnail to client/v1/media/thumbnail" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_media_tree, prefix: %w[_matrix client v3]
      )
      chain.media.thumbnail("example.com", "abc123").get(width: 32, height: 32)
      call = client.media_client.calls.last
      call[0].should == :download
      call[1].should.include "/_matrix/client/v1/media/thumbnail/"
    end

    it "does NOT rewrite non-media client/v3 paths" do
      client = StubClientWithMedia.new
      tree = make_tree
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: tree, prefix: %w[_matrix client v3]
      )
      chain.account.whoami.get
      call = client.calls.last
      call[1].should == "/_matrix/client/v3/account/whoami"
    end

    it "does NOT rewrite media/v3 paths that are not create" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_full_media_tree, prefix: %w[_matrix media v3]
      )
      chain.config.get
      call = client.calls.last
      call[0].should == :get
      call[1].should == "/_matrix/media/v3/config"
    end

    # ── max_retries forwarding ─────────────────────────────────

    it "forwards max_retries on get" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_tree
      )
      chain.account.whoami.get(max_retries: 0)
      client.calls.last.last[:max_retries].should == 0
    end

    it "forwards max_retries on post" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_tree
      )
      chain.createRoom.post({name: "Test"}, max_retries: 1)
      client.calls.last.last[:max_retries].should == 1
    end

    it "forwards max_retries on put" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_tree
      )
      chain.profile("@user:ex.com").displayname.put({displayname: "Bob"}, max_retries: 2)
      client.calls.last.last[:max_retries].should == 2
    end

    it "forwards nil max_retries by default" do
      client = StubClientWithMedia.new
      chain = Async::Matrix::Api::Chain.new(
        client: client, path_tree: make_tree
      )
      chain.account.whoami.get
      client.calls.last.last[:max_retries].should.be.nil
    end
  end
