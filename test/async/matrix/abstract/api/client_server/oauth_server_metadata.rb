# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
            end

            # v1.15 added the auth metadata endpoint.
            module V1_15
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
