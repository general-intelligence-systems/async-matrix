# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the space hierarchy, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::SpaceHierarchy}.
          module SpaceHierarchy
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

            # v1.2 added the hierarchy of a space.
            module V1_2
              def self.included(base)
                # A room is its own hierarchy where it holds nothing else, which is enough to walk.
                base.it "can getSpaceHierarchy" do
                  hierarchy = client.space_hierarchy.get_space_hierarchy(room.id)

                  expect(hierarchy.rooms.map{|found| found[:room_id]}).to be(:include?, room.id)
                end

                base.it "takes only the rooms the space suggests where it is asked to" do
                  expect(client.space_hierarchy.get_space_hierarchy(room.id, suggested_only: true, limit: 1).rooms).to be_a(Array)
                end
              end
            end

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("space hierarchy cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if SpaceHierarchy.const_defined?(name, false)
                  include SpaceHierarchy.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
