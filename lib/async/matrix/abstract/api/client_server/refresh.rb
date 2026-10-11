# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Refresh}.
        module Refresh
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

          # v1.3 added the refresh endpoint.
          module V1_3
            # Exchange a refresh token for a new access token.
            #
            # @parameter refresh_token [String] the refresh token to exchange.
            # @returns [Refreshed] the tokens the homeserver issued.
            def refresh(refresh_token)
              api::Refreshed.post(@resource.with(path: "#{V3}/refresh"), {refresh_token: refresh_token})
            end
          end

          # No changes in v1.2.
          module V1_2
          end

          # No changes in v1.1.
          module V1_1
          end
        end

        # Layers for {ruby Async::Matrix::ClientServer::Refreshed}.
        module Refreshed
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

          # v1.3 added the refresh endpoint and its response.
          module V1_3
            # @returns [String] the access token to authenticate with from now on.
            def access_token
              self.value[:access_token]
            end

            # @returns [String | nil] the token for the next refresh, if the homeserver rotated it.
            def refresh_token
              self.value[:refresh_token]
            end

            # @returns [Integer | nil] how long the new access token lasts, in milliseconds.
            def expires_in_ms
              self.value[:expires_in_ms]
            end
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
