# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::UserDevices}.
        module UserDevices
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

          # v1.1 asked a server for a user's devices.
          module V1_1
            # The devices a user has, as the server which owns them reports.
            #
            # @parameter user_id [String] the user to ask about.
            # @returns [Devices] the devices, and the stream they were read at.
            def get_user_devices(user_id)
              path = "#{FEDERATION_V1}/user/devices/#{::Protocol::URL::Encoding.escape(user_id)}"

              api::Devices.get(@resource.with(path: path))
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::Devices}.
        module Devices
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

          # v1.1 answered with the devices and a stream ID.
          module V1_1
            # @returns [String | nil] the user the devices belong to.
            def user_id
              self.value[:user_id]
            end

            # What a later update is ordered against, so a server can tell stale from fresh.
            #
            # @returns [Integer | nil] the stream position this list was read at.
            def stream_id
              self.value[:stream_id]
            end

            # @returns [Array(Hash)] the devices, each with its keys.
            def devices
              self.value[:devices] || []
            end

            # @returns [Hash | nil] the key which signs the user's other cross signing keys.
            def master_key
              self.value[:master_key]
            end

            # @returns [Hash | nil] the key which signs the user's own devices.
            def self_signing_key
              self.value[:self_signing_key]
            end

            # @returns [Boolean] whether the user has no devices.
            def empty?
              self.devices.empty?
            end
          end
        end
      end
    end
  end
end
