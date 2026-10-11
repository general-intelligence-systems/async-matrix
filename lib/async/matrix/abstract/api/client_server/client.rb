# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Client}.
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
            # @returns [OAuthServerMetadata] where the authorization server is.
            def oauth_server_metadata
              api::OAuthServerMetadata.for(self)
            end

            # The authorization server this homeserver delegates authentication to.
            #
            # The caller closes it: it is a connection to another host.
            def authorization_server
              OAuth::AuthorizationServer.for(self.oauth_server_metadata.get_auth_metadata)
            end

            # Derive a client which authenticates with tokens the authorization server issued.
            #
            # The tokens are renewed at the authorization server rather than the homeserver.
            def authorized(tokens, server:, client_id:, client_secret: nil)
              self.with_credentials(
                Credentials.new(OAuth::Issuer.new(server, client_id, client_secret),
                  access_token: tokens.access_token,
                  refresh_token: tokens.refresh_token,
                  expires_in_ms: tokens.expires_in_ms,
                )
              )
            end
          end

          # No changes in v1.14.
          module V1_14
          end

          # No changes in v1.13.
          module V1_13
          end

          # v1.12 renamed `server_name` to `via`.
          module V1_12
            # @returns [Symbol] the parameter name.
            def join_via_parameter
              :via
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

          # v1.3 added refresh tokens, which renew a session.
          module V1_3
            # @returns [Refresh] the endpoint which exchanges a refresh token.
            def refresh
              api::Refresh.for(self)
            end

            # Derive a client which renews its access token when the homeserver rejects it.
            def authenticated(access_token, refresh_token: nil, expires_in_ms: nil)
              self.with_credentials(
                Credentials.new(self.refresh,
                  access_token: access_token,
                  refresh_token: refresh_token,
                  expires_in_ms: expires_in_ms,
                )
              )
            end

            # Log in, optionally asking for a refresh token as well.
            #
            # Off by default: a refreshable access token expires, where one without a refresh token does not.
            def login(user, password, refresh_token: false, **options)
              if refresh_token
                super(user, password, refresh_token: true, **options)
              else
                super(user, password, **options)
              end
            end

            # Log in and derive a client which can renew its own access token.
            def logged_in(user, password, refresh_token: true, **options)
              login = self.login(user, password, refresh_token: refresh_token, **options)

              self.authenticated(login.access_token, refresh_token: login.refresh_token, expires_in_ms: login.expires_in_ms)
            end

            # Log in with a single use token, asking for a refresh token as well.
            def login_with_token(token, refresh_token: false, **options)
              if refresh_token
                super(token, refresh_token: true, **options)
              else
                super(token, **options)
              end
            end

            # Log in with a single use token, and derive a client which can renew its own access token.
            def logged_in_with_token(token, refresh_token: true, **options)
              login = self.login_with_token(token, refresh_token: refresh_token, **options)

              self.authenticated(login.access_token, refresh_token: login.refresh_token, expires_in_ms: login.expires_in_ms)
            end
          end

          # No changes in v1.2.
          module V1_2
          end

          # v1.1 carries what the later layers change.
          module V1_1
            # @returns [Symbol] the parameter name.
            def join_via_parameter
              :server_name
            end
          end
        end
      end
    end
  end
end
