# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the client operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module Client
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
            end

            # v1.15 added the OAuth 2.0 API.
            module V1_15
              # Stands in for the authorization server, recording what a renewal carried.
              class FakeAuthorizationServer
                def initialize
                  @renewals = []
                  @closed = false
                end

                # @attribute [Array(Hash)] what each renewal carried.
                attr :renewals

                # @attribute [Boolean] whether it was closed.
                attr :closed

                # Asked for whether or not the client has one: {Async::Matrix::OAuth::Issuer} renews with a nil secret rather than without the field.
                def refresh(refresh_token, client_id:, client_secret: nil)
                  @renewals << {refresh_token: refresh_token, client_id: client_id, client_secret: client_secret}

                  FakeTokens.new("a-renewed-token", "a-new-refresh-token", 300_000)
                end

                def close
                  @closed = true
                end
              end

              # The tokens the authorization server issued.
              FakeTokens = Struct.new(:access_token, :refresh_token, :expires_in_ms)

              # The tokens a successful authorization would have produced.
              def oauth_tokens
                FakeTokens.new("an-access-token", "a-refresh-token", 300_000)
              end

              def self.included(base)
                base.it "authenticates with the token the authorization server issued" do
                  authorized = unauthenticated.authorized(oauth_tokens, server: FakeAuthorizationServer.new, client_id: "a-client")

                  expect(authorized.delegate.credentials.access_token).to be == "an-access-token"
                end

                base.it "can renew, because the authorization server issues the tokens" do
                  authorized = unauthenticated.authorized(oauth_tokens, server: FakeAuthorizationServer.new, client_id: "a-client")

                  expect(authorized.delegate.credentials).to be(:renewable?)
                  expect(authorized.delegate.credentials.expires_at).to be_a(Time)
                end

                # The token goes below the resource, so it is not copied into every resource derived from this one.
                base.it "does not carry the token in its headers" do
                  authorized = unauthenticated.authorized(oauth_tokens, server: FakeAuthorizationServer.new, client_id: "a-client")

                  expect(authorized.headers["authorization"]).to be_nil
                  expect(authorized.inspect).not.to be(:include?, "an-access-token")
                end

                base.it "renews at the authorization server rather than the homeserver" do
                  server = FakeAuthorizationServer.new
                  authorized = unauthenticated.authorized(oauth_tokens, server: server, client_id: "a-client")

                  authorized.delegate.credentials.renew!

                  expect(server.renewals).to be == [{refresh_token: "a-refresh-token", client_id: "a-client", client_secret: nil}]
                end

                base.it "adopts the tokens a renewal issued" do
                  authorized = unauthenticated.authorized(oauth_tokens, server: FakeAuthorizationServer.new, client_id: "a-client")
                  credentials = authorized.delegate.credentials

                  credentials.renew!

                  expect(credentials.access_token).to be == "a-renewed-token"
                  expect(credentials.refresh_token).to be == "a-new-refresh-token"
                  expect(credentials.generation).to be == 1
                end

                # The authorization server is a connection to another host, which nothing else will close.
                base.it "closes the authorization server with the client" do
                  server = FakeAuthorizationServer.new
                  authorized = unauthenticated.authorized(oauth_tokens, server: server, client_id: "a-client")

                  authorized.close

                  expect(server.closed).to be == true
                end
              end
            end

            # No changes in v1.14.
            module V1_14
            end

            # No changes in v1.13.
            module V1_13
            end

            # v1.12 added the `via` parameter to joining.
            module V1_12
              def self.included(base)
                base.it "joins through the servers named by via" do
                  expect(client.join_room(room.id, via: ["localhost"]).id).to be == room.id
                end
              end
            end

            # No changes in v1.11.
            module V1_11
            end

            # No changes in v1.10.
            module V1_10
            end

            # No changes in v1.9.
            module V1_9
            end

            # No changes in v1.8.
            module V1_8
            end

            # No changes in v1.7.
            module V1_7
            end

            # No changes in v1.6.
            module V1_6
            end

            # No changes in v1.5.
            module V1_5
            end

            # No changes in v1.4.
            module V1_4
            end

            # No changes in v1.3.
            module V1_3
            end

            # No changes in v1.2.
            module V1_2
            end

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("client cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Client.const_defined?(name, false)
                  include Client.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
