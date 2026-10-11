# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the mutual rooms, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::MutualRooms}.
          module MutualRooms
            # v1.19 added the rooms two users share.
            module V1_19
              def self.included(base)
                base.let(:other){unauthenticated.logged_in("other-#{SecureRandom.hex(6)}", Async::Matrix::TEST_PASSWORD)}

                base.let(:other_id){other.get_token_owner.user_id}

                base.it "can getMutualRooms" do
                  shared = client.mutual_rooms.get_mutual_rooms(other_id)

                  expect(shared.joined).to be_a(Array)
                  expect(shared).to be(:empty?)
                end

                # A room both are joined to is a room they share.
                base.it "answers with the rooms both users are in" do
                  client.inviting.invite_user(room.id, other_id)
                  other.room(room.id).join_room_by_id

                  expect(client.mutual_rooms.get_mutual_rooms(other_id).joined).to be(:include?, room.id)
                end
              end
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
            # The cases required at the version under test.
            CASES = Sus::Shared("mutual rooms cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if MutualRooms.const_defined?(name, false)
                  include MutualRooms.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
