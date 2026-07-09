# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "forwardable"
require "json"
require "grape"
require "console"

module Async
  module Matrix
    module ApplicationService
      # Matrix Application Service (server side).
      #
      # A +Server+ wraps a Grape::API into which the Matrix wire-protocol routes
      # are mixed (via the {Server::Grape} concern). It forwards the Grape route
      # DSL, so you can declare application-specific endpoints right alongside
      # the Matrix routes, and register event handlers with #dispatch:
      #
      #   server = Async::Matrix::ApplicationService::Server.new(
      #     hs_token: config.appservice.hs_token,
      #     client:   Async::Matrix::Client.new(config)
      #   ) do
      #     dispatch do
      #       on "m.room.member" do |event|
      #         join_room(event.room_id) if event.content.membership == "invite"
      #       end
      #     end
      #
      #     dispatch SomeHandler.new       # plain handler or Bot
      #
      #     post "/_webhook/send" do       # your own endpoint, no Matrix auth
      #       client.send_text(params[:room_id], params[:body])
      #       {ok: true}
      #     end
      #   end
      #
      #   run server
      #
      # +Server+ is a Rack app (it delegates #call to the wrapped Grape::API), so
      # `run server` works directly, and it can be mounted into a larger Rack app.
      #
      # {Server::Grape} is a plain mix-in, so you can also skip +Server+ entirely
      # and mix the routes straight into your own Grape::API:
      #
      #   class MyAppService < Grape::API
      #     include Async::Matrix::ApplicationService::Server::Grape
      #     post("/_webhook/send") { ... }
      #   end
      #   MyAppService.configure { |c| c[:hs_token] = ...; c[:dispatcher] = ... }
      class Server
        extend Forwardable

        # The Matrix Application Service wire protocol, as an includable concern.
        # Mixing it into a Grape::API defines these routes (all under
        # /_matrix/app/v1), reading its collaborators from Grape +configuration+:
        #   configuration[:hs_token]    — homeserver token (authentication)
        #   configuration[:dispatcher]  — Dispatcher receiving transactions
        #   configuration[:thirdparty]  — optional third-party lookup handler
        #   configuration[:client]      — optional Client (exposed to endpoints)
        #
        # Routes:
        #   PUT  transactions/{txnId}        — receive events (authenticated)
        #   POST ping                        — healthcheck (unauthenticated)
        #   GET  users/{userId}              — user existence query (authenticated)
        #   GET  rooms/{roomAlias}           — room alias query (authenticated)
        #   GET  thirdparty/protocol/{proto} — protocol metadata (authenticated)
        #   GET  thirdparty/location         — location lookup (authenticated)
        #   GET  thirdparty/location/{proto} — reverse location lookup (authenticated)
        #   GET  thirdparty/user             — user lookup (authenticated)
        #   GET  thirdparty/user/{proto}     — reverse user lookup (authenticated)
        #
        # Third-party queries delegate to configuration[:thirdparty], a duck type:
        #   protocol(name)           -> Hash | nil   (nil ⇒ 404 M_NOT_FOUND)
        #   locations(proto, params) -> Array        (default [])
        #   users(proto, params)     -> Array        (default [])
        module Grape
          def self.included(base)
            base.class_eval do
              format :json
              content_type :json, "application/json"
              default_format :json

              helpers do
                def hs_token
                  configuration[:hs_token]
                end

                def dispatcher
                  configuration[:dispatcher]
                end

                def thirdparty
                  configuration[:thirdparty]
                end

                def client
                  configuration[:client]
                end

                # Homeserver token from the Authorization header (Bearer scheme)
                # or the legacy access_token query parameter.
                def request_token
                  auth = headers["Authorization"]
                  if auth&.start_with?("Bearer ")
                    auth.delete_prefix("Bearer ")
                  else
                    params[:access_token]
                  end
                end

                def authenticate!
                  token = request_token
                  unless token && secure_compare(token, hs_token.to_s)
                    error!({errcode: "M_FORBIDDEN"}, 403)
                  end
                end

                def secure_compare(a, b)
                  return false unless a.bytesize == b.bytesize

                  l = a.unpack("C*")
                  r = b.unpack("C*")
                  result = 0
                  l.each_with_index { |byte, i| result |= byte ^ r[i] }
                  result.zero?
                end

                # Raw JSON body, parsed here (rather than via Grape's param
                # coercion) so malformed input yields the Matrix M_BAD_JSON.
                def json_body
                  raw = request.body.read
                  request.body.rewind if request.body.respond_to?(:rewind)
                  return {} if raw.nil? || raw.empty?

                  JSON.parse(raw)
                rescue JSON::ParserError => e
                  Console.error(self) { "Bad JSON in request: #{e.message}" }
                  error!({errcode: "M_BAD_JSON"}, 400)
                end
              end

              # --- Healthcheck (unauthenticated) -----------------------------

              post "/_matrix/app/v1/ping" do
                status 200
                {}
              end

              # --- Authenticated homeserver-facing routes --------------------

              namespace "/_matrix/app/v1" do
                before { authenticate! }

                put "transactions/:txn_id" do
                  body = json_body
                  Console.info(self) do
                    events = body["events"] || []
                    "Transaction #{params[:txn_id]}: #{events.size} event(s)"
                  end
                  dispatcher.receive_transaction(params[:txn_id], body)
                  {}
                end

                get "users/:user_id", requirements: {user_id: %r{[^/]+}} do
                  {}
                end

                get "rooms/:room_alias", requirements: {room_alias: %r{[^/]+}} do
                  error!({errcode: "M_NOT_FOUND"}, 404)
                end

                # --- Third-party protocol lookups ---

                get "thirdparty/protocol/:protocol" do
                  result = thirdparty&.protocol(params[:protocol])
                  error!({errcode: "M_NOT_FOUND"}, 404) unless result

                  result
                end

                get "thirdparty/location" do
                  thirdparty&.locations(nil, params) || []
                end

                get "thirdparty/location/:protocol" do
                  thirdparty&.locations(params[:protocol], params) || []
                end

                get "thirdparty/user" do
                  thirdparty&.users(nil, params) || []
                end

                get "thirdparty/user/:protocol" do
                  thirdparty&.users(params[:protocol], params) || []
                end
              end
            end
          end
        end

        # Grape route DSL — forwarded to the wrapped API, so app-specific
        # endpoints declared in the Server.new block land on the same Grape::API
        # as the Matrix routes. `mount` is included, so you can compose in other
        # Grape APIs too.
        def_delegators :@api,
          :get, :post, :put, :patch, :delete, :head, :options,
          :namespace, :group, :resource, :resources, :route, :route_param,
          :before, :after, :rescue_from, :helpers, :params, :desc, :use, :mount,
          :version, :prefix, :format, :content_type,
          # Rack + introspection:
          :call, :routes, :recognize_path

        attr_reader :api, :dispatcher, :client

        def initialize(hs_token:, dispatcher: Dispatcher.new, client: nil, thirdparty: nil, &block)
          @dispatcher = dispatcher
          @client     = client

          # A fresh Grape::API with the Matrix routes mixed in, configured with
          # our collaborators. No mounting — the routes are defined inline by the
          # concern, so adding app-specific routes never triggers a re-mount.
          @api = ::Class.new(::Grape::API)
          @api.include(Grape)
          @api.configure do |c|
            c[:hs_token]   = hs_token
            c[:dispatcher] = dispatcher
            c[:thirdparty] = thirdparty
            c[:client]     = client
          end

          instance_eval(&block) if block
        end

        # Register handlers with the dispatcher. Sugar over dispatcher.register:
        #
        #   dispatch do                          # block → Bot built with `client`
        #     on "m.room.message" do |e| ... end
        #   end
        #   dispatch Bot.new(other_client) { }   # explicit bot
        #   dispatch SomeHandler.new             # plain handler
        #
        def dispatch(handler = nil, &block)
          if block
            unless @client
              raise ArgumentError, "dispatch { ... } needs a client; pass `client:` to Server.new"
            end

            @dispatcher.register(Bot.new(@client, &block))
          elsif handler
            @dispatcher.register(handler)
          else
            raise ArgumentError, "dispatch requires a handler argument or a block"
          end
          @dispatcher
        end
      end
    end
  end
end

__END__
  require "rack/mock"

  describe "Async::Matrix::ApplicationService::Server" do
    Server = Async::Matrix::ApplicationService::Server
    Dispatcher = Async::Matrix::ApplicationService::Dispatcher

    # Positional opts hash (not kwargs) so the helper survives scampi's
    # nested-describe delegation, which forwards via *args.
    def mock_req(app, method, path, opts = {})
      env = {}
      env["HTTP_AUTHORIZATION"] = "Bearer #{opts[:token]}" if opts[:token]
      if opts[:body]
        env["CONTENT_TYPE"] = "application/json"
        env[:input] = opts[:body]
      end
      Rack::MockRequest.new(app).request(method, path, env)
    end

    def build(hs_token: "secret", dispatcher: nil, client: nil, thirdparty: nil, &block)
      Server.new(hs_token: hs_token, dispatcher: dispatcher || Dispatcher.new,
        client: client, thirdparty: thirdparty, &block)
    end

    # --- Matrix wire protocol ---

    it "responds to POST /ping with 200 (no auth required)" do
      mock_req(build, "POST", "/_matrix/app/v1/ping").status.should == 200
    end

    it "rejects GET /ping with 405" do
      mock_req(build, "GET", "/_matrix/app/v1/ping").status.should == 405
    end

    it "rejects transactions without a token" do
      mock_req(build, "PUT", "/_matrix/app/v1/transactions/txn1", body: "{}").status.should == 403
    end

    it "rejects transactions with wrong token" do
      app = build(hs_token: "correct")
      mock_req(app, "PUT", "/_matrix/app/v1/transactions/txn1", token: "wrong", body: "{}").status.should == 403
    end

    it "accepts valid transactions with Bearer auth" do
      mock_req(build, "PUT", "/_matrix/app/v1/transactions/txn1",
        token: "secret", body: '{"events":[]}').status.should == 200
    end

    it "dispatches events from a transaction" do
      received = []
      handler = Object.new
      handler.define_singleton_method(:event_types) { ["m.room.message"] }
      handler.define_singleton_method(:call) { |e| received << e }

      app = build { dispatch handler }
      mock_req(app, "PUT", "/_matrix/app/v1/transactions/txn_disp", token: "secret",
        body: '{"events":[{"type":"m.room.message","content":{"body":"hi"}}]}')
      received.length.should == 1
    end

    it "deduplicates transactions" do
      received = []
      handler = Object.new
      handler.define_singleton_method(:event_types) { ["m.room.message"] }
      handler.define_singleton_method(:call) { |e| received << e }

      app = build { dispatch handler }
      body = '{"events":[{"type":"m.room.message","content":{"body":"hi"}}]}'
      mock_req(app, "PUT", "/_matrix/app/v1/transactions/dup", token: "secret", body: body)
      resp = mock_req(app, "PUT", "/_matrix/app/v1/transactions/dup", token: "secret", body: body)

      resp.status.should == 200
      received.length.should == 1
    end

    it "rejects bad JSON with 400" do
      mock_req(build, "PUT", "/_matrix/app/v1/transactions/txn1",
        token: "secret", body: "not json").status.should == 400
    end

    it "responds 200 for user queries" do
      mock_req(build, "GET", "/_matrix/app/v1/users/@bot:localhost", token: "secret").status.should == 200
    end

    it "responds 404 for room queries" do
      mock_req(build, "GET", "/_matrix/app/v1/rooms/%23room:localhost", token: "secret").status.should == 404
    end

    it "returns [] for third-party user lookup with no handler" do
      resp = mock_req(build, "GET", "/_matrix/app/v1/thirdparty/user", token: "secret")
      resp.status.should == 200
      resp.body.should == "[]"
    end

    it "404s third-party protocol lookup with no handler" do
      mock_req(build, "GET", "/_matrix/app/v1/thirdparty/protocol/irc", token: "secret").status.should == 404
    end

    it "delegates third-party protocol lookup to the handler" do
      tp = Object.new
      tp.define_singleton_method(:protocol) { |name| {"instances" => [], "name" => name} }
      app = build(thirdparty: tp)
      resp = mock_req(app, "GET", "/_matrix/app/v1/thirdparty/protocol/irc", token: "secret")
      resp.status.should == 200
      JSON.parse(resp.body)["name"].should == "irc"
    end

    it "responds 404 for unknown paths" do
      mock_req(build, "GET", "/unknown").status.should == 404
    end

    # --- App-specific endpoints via the forwarded DSL ---

    it "serves app-specific routes declared with the forwarded post DSL" do
      app = build do
        post "/_webhook/send" do
          {ok: true}
        end
      end
      resp = mock_req(app, "POST", "/_webhook/send")
      resp.status.should == 201
      JSON.parse(resp.body)["ok"].should == true
    end

    it "does not require Matrix auth for app-specific routes" do
      app = build { post("/_webhook/send") { {ok: true} } }
      mock_req(app, "POST", "/_webhook/send").status.should == 201
    end

    it "does not duplicate the Matrix routes when app routes are added" do
      app = build { post("/_webhook/send") { {} } }
      ping_routes = app.routes.select { |r| r.path.include?("/ping") }
      ping_routes.length.should == 1
    end

    # --- dispatch DSL ---

    it "dispatch { on ... } builds a Bot from the block using the client" do
      config = Async::Matrix::ApplicationService::Config.new({
        "homeserver" => {"address" => "http://localhost:8008", "domain" => "localhost"},
        "appservice" => {"as_token" => "a", "hs_token" => "secret", "bot" => {"username" => "bot"}}
      })
      bot_client = Async::Matrix::Client.new(config)

      app = build(client: bot_client) do
        dispatch do
          on "m.room.message" do |event|
            # not executed in this test
          end
        end
      end
      app.dispatcher.handler_count.should == 1
    end

    it "dispatch { } without a client raises ArgumentError" do
      lambda { build { dispatch { on("m.room.message") { |e| } } } }.should.raise(ArgumentError)
    end

    it "isolates dispatcher and routes between instances" do
      a = build(hs_token: "token_a") { post("/only_a") { {} } }
      b = build(hs_token: "token_b")
      mock_req(a, "PUT", "/_matrix/app/v1/transactions/x", token: "token_b", body: "{}").status.should == 403
      mock_req(a, "PUT", "/_matrix/app/v1/transactions/x", token: "token_a", body: "{}").status.should == 200
      # /only_a exists on `a` but not on `b`
      mock_req(a, "POST", "/only_a").status.should == 201
      mock_req(b, "POST", "/only_a").status.should == 404
    end
  end
