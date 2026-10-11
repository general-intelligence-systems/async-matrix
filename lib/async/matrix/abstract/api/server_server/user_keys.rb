# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::UserKeys}.
        module UserKeys
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

          # v1.1 queried and claimed another server's keys.
          module V1_1
            # The device keys of users another server owns.
            #
            # @parameter device_keys [Hash] the devices wanted, by user ID, or all of a user's for an empty list.
            # @returns [DeviceKeys] the keys.
            def query_user_encryption_keys(device_keys)
              path = "#{FEDERATION_V1}/user/keys/query"

              api::DeviceKeys.post(@resource.with(path: path), {device_keys: device_keys})
            end

            # Claim a one time key, which is handed out once and then gone.
            #
            # @parameter one_time_keys [Hash] the algorithm wanted, by user ID and device ID.
            # @returns [ClaimedKeys] the keys which were claimed.
            def claim_user_encryption_keys(one_time_keys)
              path = "#{FEDERATION_V1}/user/keys/claim"

              api::ClaimedKeys.post(@resource.with(path: path), {one_time_keys: one_time_keys})
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::DeviceKeys}.
        module DeviceKeys
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

          # v1.1 answered with the device and cross signing keys.
          module V1_1
            # @returns [Hash] the keys of each device, by user ID.
            def device_keys
              self.value[:device_keys] || {}
            end

            # @returns [Hash] the key which signs a user's other cross signing keys, by user ID.
            def master_keys
              self.value[:master_keys] || {}
            end

            # @returns [Hash] the key which signs a user's own devices, by user ID.
            def self_signing_keys
              self.value[:self_signing_keys] || {}
            end

            # The devices of one user, which is the answer a caller usually wants.
            #
            # @parameter user_id [String] the user to read.
            # @returns [Hash] their devices, by device ID.
            def devices_of(user_id)
              self.device_keys[user_id.to_sym] || {}
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::ClaimedKeys}.
        module ClaimedKeys
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

          # v1.1 answered with the keys it handed over.
          module V1_1
            # A key is handed out once, so what came back may be less than was asked for.
            #
            # @returns [Hash] the keys, by user ID and device ID.
            def one_time_keys
              self.value[:one_time_keys] || {}
            end

            # @returns [Boolean] whether nothing was handed over.
            def empty?
              self.one_time_keys.empty?
            end
          end
        end
      end
    end
  end
end
