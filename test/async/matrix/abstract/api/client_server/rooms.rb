# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the rooms operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module Rooms
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

            # v1.12 added the `via` parameter to joining.
            module V1_12
              def self.included(base)
                base.it "joins through the servers named by via" do
                  expect(room.join_room_by_id(via: ["localhost"]).room_id).to be == room.id
                end
              end
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

            # v1.3 made `from` optional when paging the timeline.
            module V1_3
              def self.included(base)
                base.it "pages the timeline without a from token" do
                  room.send_message("m.room.message", {msgtype: "m.text", body: "paged without a token"})

                  expect(room.get_room_events(limit: 1).events).not.to be(:empty?)
                end
              end
            end

            # No changes in v1.2.
            module V1_2
            end

            # v1.1 is the oldest version, and carries every room case.
            module V1_1
              def self.included(base)
                base.it "can createRoom" do
                  expect(client.create_room(name: "Created").id).to be =~ /\A!/
                end

                base.it "can getJoinedRooms" do
                  room

                  expect(client.get_joined_rooms.ids).to be(:include?, room.id)
                end

                base.it "can getRoomState" do
                  expect(room.get_room_state.name).to be == Async::Matrix::TEST_ROOM_NAME
                end

                base.it "can getJoinedMembersByRoom" do
                  expect(room.get_joined_members_by_room.user_ids).to be(:include?, self.user_id)
                end

                base.it "can getRoomEvents" do
                  room.send_message("m.room.message", {msgtype: "m.text", body: "paged"})

                  expect(room.get_room_events(limit: 10).events).not.to be(:empty?)
                end

                base.it "can sendMessage" do
                  expect(room.send_message("m.room.message", {msgtype: "m.text", body: "sent"}).event_id).to be =~ /\A\$/
                end

                base.it "can joinRoomById" do
                  # Joining a room you are in succeeds, which is the simplest way to exercise it.
                  expect(room.join_room_by_id.room_id).to be == room.id
                end

                base.it "can joinRoom" do
                  expect(client.join_room(room.id).id).to be == room.id
                end

                base.it "can leaveRoom" do
                  room.leave_room

                  expect(client.get_joined_rooms.ids).not.to be(:include?, room.id)
                end

                base.it "can getMembersByRoom" do
                  expect(room.get_members_by_room.user_ids).to be(:include?, self.user_id)
                end

                base.it "can getOneRoomEvent" do
                  sent = room.send_message("m.room.message", {msgtype: "m.text", body: "fetched by id"})

                  expect(room.get_one_room_event(sent.event_id).content[:body]).to be == "fetched by id"
                end

                base.it "can setRoomStateWithKey" do
                  expect(room.set_room_state_with_key("m.room.topic", {topic: "set"}).event_id).to be =~ /\A\$/
                end

                base.it "can getRoomStateWithKey" do
                  room.set_room_state_with_key("m.room.topic", {topic: "read back"})

                  expect(room.get_room_state_with_key("m.room.topic").content[:topic]).to be == "read back"
                end

                base.it "can forgetRoom" do
                  room.leave_room

                  expect(room.forget_room).not.to be_nil
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("room cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Rooms.const_defined?(name, false)
                  include Rooms.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
