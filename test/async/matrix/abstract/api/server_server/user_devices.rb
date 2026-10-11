# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the devices a user has, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::UserDevices}.
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
              def self.included(base)
                # Logging in is what makes a device, so the account is made through the client.
                base.let(:member){client.get_token_owner.user_id}

                base.it "can getUserDevices" do
                  devices = server.user_devices.get_user_devices(member)

                  expect(devices.user_id).to be == member
                  expect(devices.stream_id).not.to be_nil
                end

                base.it "reads the devices as a list" do
                  expect(server.user_devices.get_user_devices(member).devices).to be_a(Array)
                end

                # A user nobody has heard of is answered for rather than refused: there is nothing secret about having no devices.
                base.it "answers for a user who has no devices" do
                  expect(server.user_devices.get_user_devices("@nobody-at-all:#{server_name}")).to be(:empty?)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("user devices cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if UserDevices.const_defined?(name, false)
                  include UserDevices.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
