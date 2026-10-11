# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::OAuthServerMetadata}.
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
            # Where the authorization server is, and what it supports.
            #
            # @returns [AuthMetadata] the metadata.
            def get_auth_metadata
              api::AuthMetadata.get(@resource.with(path: "#{V1}/auth_metadata"))
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
        end

        # Layers for {ruby Async::Matrix::ClientServer::AuthMetadata}.
        module AuthMetadata
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 added the account management and device authorization fields.
          module V1_18
            # @returns [String | nil] where the user manages their account.
            def account_management_uri
              self.value[:account_management_uri]
            end

            # @returns [Array(String)] the actions the account management url supports.
            def account_management_actions_supported
              self.value[:account_management_actions_supported] || []
            end

            # @returns [String | nil] where a client asks for a device authorization grant.
            def device_authorization_endpoint
              self.value[:device_authorization_endpoint]
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
            # @returns [String] the authorization server which issues the tokens.
            def issuer
              self.value[:issuer]
            end

            # @returns [String] where the user is sent to authorize a client.
            def authorization_endpoint
              self.value[:authorization_endpoint]
            end

            # @returns [String] where an authorization code is redeemed.
            def token_endpoint
              self.value[:token_endpoint]
            end

            # @returns [String | nil] where a client registers itself.
            def registration_endpoint
              self.value[:registration_endpoint]
            end

            # @returns [String | nil] where a token is revoked.
            def revocation_endpoint
              self.value[:revocation_endpoint]
            end

            # @returns [Array(String)] the grant types the server supports.
            def grant_types_supported
              self.value[:grant_types_supported] || []
            end

            # @returns [Array(String)] the response types the server supports.
            def response_types_supported
              self.value[:response_types_supported] || []
            end

            # @returns [Array(String)] the challenge methods the server supports.
            def code_challenge_methods_supported
              self.value[:code_challenge_methods_supported] || []
            end

            # @parameter method [String] the challenge method, e.g. `S256`.
            # @returns [Boolean] whether the server accepts that method.
            def supports_challenge?(method)
              self.code_challenge_methods_supported.include?(method)
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
        end
      end
    end
  end
end
