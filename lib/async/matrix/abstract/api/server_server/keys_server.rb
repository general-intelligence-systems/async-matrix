# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::KeysServer}.
        module KeysServer
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

          # v1.6 dropped the deprecated key ID from the path.
          module V1_6
            # The keys a server signs with, which it publishes for itself.
            #
            # @returns [PublishedKeys] the keys, signed by the server they belong to.
            def get_server_key
              api::PublishedKeys.get(@resource.with(path: "#{KEY_V2}/server"))
            end
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

          # v1.1 published the keys a server signs with.
          module V1_1
            # The keys a server signs with, which it publishes for itself.
            #
            # @returns [PublishedKeys] the keys, signed by the server they belong to.
            def get_server_key
              # The key ID segment is deprecated and not required, so it is left empty rather than asked for.
              api::PublishedKeys.get(@resource.with(path: "#{KEY_V2}/server/"))
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::PublishedKeys}.
        module PublishedKeys
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

          # No changes in v1.3.
          module V1_3
          end

          # No changes in v1.2.
          module V1_2
          end

          # v1.1 answered with the keys and their lifetime.
          module V1_1
            # @returns [String | nil] the server these keys belong to.
            def server_name
              self.value[:server_name]
            end

            # @returns [Hash] the keys which are still being signed with, by ID.
            def verify_keys
              self.value[:verify_keys] || {}
            end

            # @returns [Hash] the keys which are no longer signed with but still verify, by ID.
            def old_verify_keys
              self.value[:old_verify_keys] || {}
            end

            # The document signs itself: the keys are signed by the keys they publish.
            #
            # @returns [Hash] the signatures, by server name.
            def signatures
              self.value[:signatures] || {}
            end

            # @returns [Integer | nil] when the keys stop being valid, in milliseconds since the epoch.
            def valid_until_ts
              self.value[:valid_until_ts]
            end

            # One key, whether or not it is still being signed with.
            #
            # @parameter id [String] the key ID, e.g. `ed25519:a_pxTp`.
            # @returns [String | nil] the key, as unpadded base64.
            def verify_key(id)
              entry = self.verify_keys[id.to_sym] || self.old_verify_keys[id.to_sym]

              entry && entry[:key]
            end
          end
        end
      end
    end
  end
end
