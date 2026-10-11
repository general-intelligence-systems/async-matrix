# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the rooms a space holds, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::SpaceHierarchy}.
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

            # v1.2 added spaces, and the rooms they hold.
            module V1_2
              def self.included(base)
                # A space is a room whose creation says so, and its children are state events in it.
                base.let(:space){client.create_room(preset: "public_chat", creation_content: {type: "m.space"})}

                base.it "can getSpaceHierarchy" do
                  held = room
                  space.set_room_state_with_key("m.space.child", {via: [server_name]}, held.id)

                  expect(server.space_hierarchy.get_space_hierarchy(space.id).child_ids).to be(:include?, held.id)
                end

                base.it "answers with the space it was asked about" do
                  expect(server.space_hierarchy.get_space_hierarchy(space.id).room_id).to be == space.id
                end

                # A room which is not a space holds nothing, which is an answer rather than a refusal.
                base.it "answers for a room which holds nothing" do
                  expect(server.space_hierarchy.get_space_hierarchy(room.id)).to be(:empty?)
                end

                base.it "leaves out the children which are not suggested" do
                  held = room
                  space.set_room_state_with_key("m.space.child", {via: [server_name]}, held.id)

                  expect(server.space_hierarchy.get_space_hierarchy(space.id, suggested_only: true)).to be(:empty?)
                end

                base.it "refuses a room it has never heard of" do
                  expect do
                    server.space_hierarchy.get_space_hierarchy("!nothing-at-all:#{server_name}").room
                  end.to raise_exception(Async::Matrix::RequestError)
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
