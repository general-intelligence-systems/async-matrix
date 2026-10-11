# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/http/internet"

require "async/matrix/oauth_context"
require "async/matrix/operations_context"

# Cases for the OAuth server metadata operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module OAuthServerMetadata
            # No changes in v1.19.
            module V1_19
            end

            # v1.18 added the account management and device authorization fields.
            module V1_18
              def self.included(base)
                base.it "names where the user manages their account" do
                  expect(metadata.account_management_uri).to be_a(String)
                end

                base.it "names the account management actions it supports" do
                  expect(metadata.account_management_actions_supported).to be_a(Array)
                end

                base.it "names a device authorization endpoint" do
                  expect(metadata.device_authorization_endpoint).to be_a(String)
                end
              end
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
            end

            # v1.15 added the auth metadata endpoint.
            module V1_15
              # Where the rig sends an authorization code back to.
              REDIRECT_URI = ::Async::Matrix::OAUTH_REDIRECT_URI

              # Register this application, which a public client must do before it can authorize.
              #
              # @parameter server [Async::Matrix::OAuth::AuthorizationServer] the server to register with.
              # @returns [Async::Matrix::OAuth::Registration] the client this application is now known as.
              def register_client(server)
                server.register(
                  client_name: "async-matrix",
                  application_type: "native",
                  client_uri: "https://github.com/socketry/async-matrix",
                  grant_types: ["authorization_code", "refresh_token"],
                  response_types: ["code"],
                  redirect_uris: [REDIRECT_URI],
                  token_endpoint_auth_method: "none",
                )
              end

              def self.included(base)
                base.it "can getAuthMetadata" do
                  expect(metadata.issuer).to be_a(String)
                end

                base.it "names the endpoints the flow needs" do
                  expect(metadata.authorization_endpoint).to be(:start_with?, "http")
                  expect(metadata.token_endpoint).to be(:start_with?, "http")
                  expect(metadata.registration_endpoint).to be(:start_with?, "http")
                end

                # A public client has no secret, so it can only authorize if the server takes a challenge.
                base.it "supports the challenge method a public client needs" do
                  expect(metadata).to be(:supports_challenge?, Async::Matrix::OAuth::Verifier::METHOD)
                end

                base.it "supports the grants the flow needs" do
                  expect(metadata.grant_types_supported).to be(:include?, "authorization_code")
                  expect(metadata.grant_types_supported).to be(:include?, "refresh_token")
                end

                # Registration is unauthenticated, which is how a client with no secret gets an identity.
                base.it "registers this application as a client" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)

                  registration = server.register(
                    client_name: "async-matrix",
                    application_type: "native",
                    client_uri: "https://github.com/socketry/async-matrix",
                    grant_types: ["authorization_code", "refresh_token"],
                    response_types: ["code"],
                    redirect_uris: ["http://127.0.0.1/"],
                    token_endpoint_auth_method: "none",
                  )

                  expect(registration.client_id).to be_a(String)
                  expect(registration.client_secret).to be_nil
                ensure
                  server&.close
                end

                base.it "builds an authorization url against the server" do
                  server = Async::Matrix::OAuth::AuthorizationServer.new(unauthenticated, metadata)

                  verifier = Async::Matrix::OAuth::Verifier.generate

                  url = server.authorization_url(
                    client_id: "a-client",
                    redirect_uri: "http://127.0.0.1/",
                    verifier: verifier,
                    scope: Async::Matrix::OAuth::AuthorizationServer.scope(Async::Matrix::OAuth::AuthorizationServer.device_id),
                  )

                  expect(url).to be(:start_with?, metadata.authorization_endpoint)
                  expect(url).to be(:include?, "code_challenge_method=S256")
                end

                # Everything the client controls is correct, so the server answers with its own login page rather than refusing the request.
                base.it "sends the user to a request the server accepts" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  authorization = server.authorize(client_id: register_client(server).client_id, redirect_uri: REDIRECT_URI)

                  internet = Async::HTTP::Internet.new
                  response = internet.get(authorization.url)

                  expect(response.status).to be < 400
                ensure
                  response&.close
                  internet&.close
                  server&.close
                end

                # The code is the one thing the client cannot fabricate, so this is as far as a test without a user can go: the request is well formed enough for the server to judge the grant itself.
                base.it "redeems a code at the server, which refuses one it never issued" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  authorization = server.authorize(client_id: register_client(server).client_id, redirect_uri: REDIRECT_URI)

                  error = nil

                  begin
                    authorization.exchange("not-a-code-this-server-issued", state: authorization.state)
                  rescue Async::Matrix::OAuth::Error => raised
                    error = raised
                  end

                  expect(error).not.to be_nil
                  expect(error).to be(:invalid_grant?)
                ensure
                  server&.close
                end

                # The whole flow, with the user's consent performed by the fixture as a browser would.
                base.it "is issued tokens once the user consents" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  authorization = server.authorize(client_id: register_client(server).client_id, redirect_uri: REDIRECT_URI)

                  redirected = consent_to(authorization)
                  tokens = authorization.exchange(redirected["code"], state: redirected["state"])

                  expect(tokens.access_token).to be_a(String)
                  expect(tokens.refresh_token).to be_a(String)
                  expect(tokens.token_type).to be == "Bearer"
                  expect(tokens.expires_in_ms).to be > 0
                ensure
                  server&.close
                end

                # The code is bound to the challenge, so it is useless to anyone who did not generate the verifier. Were the challenge or its method sent wrongly, the server would accept this.
                base.it "binds the code to the challenge, so another verifier cannot redeem it" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  client_id = register_client(server).client_id
                  authorization = server.authorize(client_id: client_id, redirect_uri: REDIRECT_URI)

                  redirected = consent_to(authorization)

                  error = nil

                  begin
                    server.exchange(redirected["code"],
                      client_id: client_id,
                      redirect_uri: REDIRECT_URI,
                      verifier: Async::Matrix::OAuth::Verifier.generate,
                    )
                  rescue Async::Matrix::OAuth::Error => raised
                    error = raised
                  end

                  expect(error).not.to be_nil
                  expect(error).to be(:invalid_grant?)
                ensure
                  server&.close
                end

                base.it "authenticates as the user who consented" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  client_id = register_client(server).client_id
                  authorization = server.authorize(client_id: client_id, redirect_uri: REDIRECT_URI)

                  redirected = consent_to(authorization)
                  tokens = authorization.exchange(redirected["code"], state: redirected["state"])

                  authorized = unauthenticated.authorized(tokens, server: server, client_id: client_id)
                  whoami = authorized.get_token_owner

                  expect(whoami.user_id).to be == "@#{Async::Matrix::OAUTH_USERNAME}:localhost"
                  expect(whoami.device_id).to be_a(String)
                ensure
                  authorized&.close
                end

                # The refresh token the flow issued buys a new access token, which is what keeps a long lived client working.
                base.it "renews the access token at the authorization server" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  client_id = register_client(server).client_id
                  authorization = server.authorize(client_id: client_id, redirect_uri: REDIRECT_URI)

                  redirected = consent_to(authorization)
                  tokens = authorization.exchange(redirected["code"], state: redirected["state"])

                  authorized = unauthenticated.authorized(tokens, server: server, client_id: client_id)
                  credentials = authorized.delegate.credentials

                  credentials.renew!

                  expect(credentials.access_token).not.to be == tokens.access_token
                  expect(credentials.generation).to be == 1
                  expect(authorized.get_token_owner.user_id).to be == "@#{Async::Matrix::OAUTH_USERNAME}:localhost"
                ensure
                  authorized&.close
                end

                base.it "names where a token is withdrawn" do
                  expect(metadata.revocation_endpoint).to be(:start_with?, "http")
                end

                # Logging out of the homeserver does not end a session the authorization server issued: withdrawing the token is what does.
                base.it "withdraws the tokens of a session it issued" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  client_id = register_client(server).client_id
                  authorization = server.authorize(client_id: client_id, redirect_uri: REDIRECT_URI)

                  redirected = consent_to(authorization)
                  tokens = authorization.exchange(redirected["code"], state: redirected["state"])

                  authorized = unauthenticated.authorized(tokens, server: server, client_id: client_id)

                  expect(authorized.get_token_owner.user_id).to be == "@#{Async::Matrix::OAUTH_USERNAME}:localhost"

                  # Both tokens are withdrawn, and the session is left with nothing to renew with:
                  authorized.delegate.credentials.revoke!

                  expect(authorized.delegate.credentials).not.to be(:renewable?)
                ensure
                  authorized&.close
                end

                # The authorization server is the authority for a refresh token, so this holds whatever the homeserver has cached.
                base.it "withdraws a refresh token, which can then buy nothing" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  client_id = register_client(server).client_id
                  authorization = server.authorize(client_id: client_id, redirect_uri: REDIRECT_URI)

                  redirected = consent_to(authorization)
                  tokens = authorization.exchange(redirected["code"], state: redirected["state"])

                  # Withdrawn before it is spent, because a renewal rotates it:
                  server.revoke(tokens.refresh_token, client_id: client_id, token_type_hint: "refresh_token")

                  error = nil

                  begin
                    server.refresh(tokens.refresh_token, client_id: client_id)
                  rescue Async::Matrix::OAuth::Error => raised
                    error = raised
                  end

                  expect(error).not.to be_nil
                  expect(error).to be(:invalid_grant?)
                ensure
                  server&.close
                end

                # A redirect which came back with the wrong state is never redeemed, so the server is never asked.
                base.it "refuses a redirect whose state does not match" do
                  server = Async::Matrix::OAuth::AuthorizationServer.for(metadata)
                  authorization = server.authorize(client_id: register_client(server).client_id, redirect_uri: REDIRECT_URI)

                  expect do
                    authorization.exchange("not-a-code-this-server-issued", state: "a-state-it-did-not-ask-for")
                  end.to raise_exception(Async::Matrix::OAuth::Error)
                ensure
                  server&.close
                end
              end
            end

            # No changes in v1.14.
            module V1_14
            end

            # No changes in v1.13.
            module V1_13
            end

            # No changes in v1.12.
            module V1_12
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
            CASES = Sus::Shared("oauth server metadata cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if OAuthServerMetadata.const_defined?(name, false)
                  include OAuthServerMetadata.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
