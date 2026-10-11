# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the device management operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module DeviceManagement
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

            # v1.1 is the oldest version, and carries every device case.
            module V1_1
              def self.included(base)
                base.it "can getDevices" do
                  expect(client.devices.all.ids).to be(:include?, client.whoami.device_id)
                end

                base.it "can getDevice" do
                  device_id = client.whoami.device_id

                  expect(client.devices.get(device_id).device_id).to be == device_id
                end

                base.it "can updateDevice" do
                  client.devices.update(client.whoami.device_id, display_name: "Renamed")

                  expect(client.devices.get(client.whoami.device_id).display_name).to be == "Renamed"
                end

                # Logging a device out is guarded by user interactive authentication.
                base.it "can deleteDevice" do
                  error = nil

                  begin
                    client.devices.delete(client.whoami.device_id)
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.status).to be == 401
                end

                base.it "can deleteDevices" do
                  error = nil

                  begin
                    client.devices.delete_all([client.whoami.device_id])
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.status).to be == 401
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("device management cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if DeviceManagement.const_defined?(name, false)
                  include DeviceManagement.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
