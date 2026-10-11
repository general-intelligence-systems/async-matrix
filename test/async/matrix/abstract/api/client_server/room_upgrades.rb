# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for upgrading a room, layered by version.
#
# The room version is the variable: a room can only be upgraded to a version the homeserver knows, and the rig runs the Synapse of each specification version's own era.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::RoomUpgrades}.
          module RoomUpgrades
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

            # v1.8 runs Synapse 1.98.0, which added 11.
            module V1_8
              def self.included(base)
                base.let(:upgrade_version){"11"}
              end
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

            # v1.3 runs Synapse 1.72.0, which added 10.
            module V1_3
              def self.included(base)
                base.let(:upgrade_version){"10"}
              end
            end

            # No changes in v1.2.
            module V1_2
            end

            # v1.1 runs Synapse 1.54.0, which knows up to 9.
            module V1_1
              def self.included(base)
                base.it "can upgradeRoom" do
                  expect(client.room_upgrades.upgrade_room(room.id, upgrade_version).replacement_room).to be =~ /\A!/
                end

                # The replacement is a room of its own, which this user is joined to.
                base.it "answers with a room which is not the one upgraded" do
                  replacement = client.room_upgrades.upgrade_room(room.id, upgrade_version).replacement_room

                  expect(replacement).not.to be == room.id
                  expect(client.get_joined_rooms.ids).to be(:include?, replacement)
                end

                # The newest room version the homeserver of this version knows, which a later layer raises.
                base.let(:upgrade_version){"9"}
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("room upgrades cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if RoomUpgrades.const_defined?(name, false)
                  include RoomUpgrades.const_get(name, false)
                end
              end
            end
          end

          # Cases for {ruby Async::Matrix::ClientServer::UpgradedRoom}, which the upgrade cases above cover.
          module UpgradedRoom
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

            # No changes in v1.1.
            module V1_1
            end
          end
        end
      end
    end
  end
end
