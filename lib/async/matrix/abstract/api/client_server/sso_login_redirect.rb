# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::SSOLoginRedirect}.
        module SSOLoginRedirect
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 added the action query parameter.
          module V1_18
            # Where to send the user's browser to sign in with any provider.
            #
            # @parameter redirect_url [String] where the homeserver returns the user afterwards.
            # @parameter action [String | nil] `login` or `register`, if the user has chosen.
            # @returns [String] the URL to open.
            def redirect_to_sso(redirect_url, action: nil)
              self.url_for("#{V3}/login/sso/redirect", redirectUrl: redirect_url, action: action)
            end

            # Where to send the user's browser to sign in with one named provider.
            #
            # @parameter idp_id [String] the `id` of the provider, from {ruby Async::Matrix::ClientServer::LoginFlows#identity_providers}.
            # @parameter redirect_url [String] where the homeserver returns the user afterwards.
            # @parameter action [String | nil] `login` or `register`, if the user has chosen.
            # @returns [String] the URL to open.
            def redirect_to_idp(idp_id, redirect_url, action: nil)
              path = "#{V3}/login/sso/redirect/#{::Protocol::URL::Encoding.escape(idp_id)}"

              self.url_for(path, redirectUrl: redirect_url, action: action)
            end
          end

          # No changes in v1.17.
          module V1_17
          end

          # No changes in v1.16.
          module V1_16
          end

          # No changes in v1.15.
          module V1_15
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

          # v1.1 added the single sign on redirects.
          module V1_1
            # Where to send the user's browser to sign in with any provider.
            #
            # @parameter redirect_url [String] where the homeserver returns the user afterwards.
            # @returns [String] the URL to open.
            def redirect_to_sso(redirect_url)
              self.url_for("#{V3}/login/sso/redirect", redirectUrl: redirect_url)
            end

            # Where to send the user's browser to sign in with one named provider.
            #
            # @parameter idp_id [String] the `id` of the provider, from {ruby Async::Matrix::ClientServer::LoginFlows#identity_providers}.
            # @parameter redirect_url [String] where the homeserver returns the user afterwards.
            # @returns [String] the URL to open.
            def redirect_to_idp(idp_id, redirect_url)
              path = "#{V3}/login/sso/redirect/#{::Protocol::URL::Encoding.escape(idp_id)}"

              self.url_for(path, redirectUrl: redirect_url)
            end
          end
        end
      end
    end
  end
end
