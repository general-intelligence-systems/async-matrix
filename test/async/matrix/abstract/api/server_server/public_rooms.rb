# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the rooms a server publishes, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::PublicRooms}.
          module PublicRooms
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

            # v1.1 read the rooms a server publishes.
            module V1_1
              def self.included(base)
                # Publishing is a choice: the rig turns `allow_public_rooms_over_federation` on, and the room asks to be listed.
                base.let(:published){client.create_room(name: "Published", preset: "public_chat", visibility: "public")}

                base.it "can getPublicRooms" do
                  listed = published

                  expect(server.public_rooms.get_public_rooms.room_ids).to be(:include?, listed.id)
                end

                base.it "sends no more rooms than were asked for" do
                  published

                  expect(server.public_rooms.get_public_rooms(limit: 1).chunk.size).to be <= 1
                end

                base.it "says roughly how many rooms there are" do
                  published

                  expect(server.public_rooms.get_public_rooms.total_room_count_estimate).to be >= 1
                end

                base.it "can queryPublicRooms" do
                  listed = published

                  found = server.public_rooms.query_public_rooms(filter: {generic_search_term: "Published"})

                  expect(found.room_ids).to be(:include?, listed.id)
                end

                # A filter which matches nothing is an empty page rather than a refusal.
                base.it "finds nothing where the filter matches nothing" do
                  published

                  expect(server.public_rooms.query_public_rooms(filter: {generic_search_term: "nothing-at-all"})).to be(:empty?)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("public rooms cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if PublicRooms.const_defined?(name, false)
                  include PublicRooms.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
