# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/rooms"

describe Async::Matrix::ClientServer::Room do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The cases for the operations, layered by version.
  include Async::Matrix::Testing::Abstract::ClientServer::Rooms::CASES

  with "#create_room" do
    it "creates a room which appears in the joined rooms" do
      expect(room).to be_a(Async::Matrix::ClientServer::Room)
      expect(room.id).to be =~ /\A!/

      expect(client.get_joined_rooms).to be(:include?, room.id)
    end

    it "enumerates joined rooms as rooms" do
      room

      rooms = client.get_joined_rooms.to_a

      expect(rooms).not.to be(:empty?)
      expect(rooms.first).to be_a(Async::Matrix::ClientServer::Room)

      # The room resource is derived with an absolute path, replacing `/joined_rooms`:
      expect(rooms.first.resource.path.to_s).to be =~ %r{\A/_matrix/client/v3/rooms/}
    end
  end

  with "#state" do
    it "can read the room state" do
      state = room.get_room_state

      expect(state.name).to be == Async::Matrix::TEST_ROOM_NAME
      expect(state.topic).to be == Async::Matrix::TEST_ROOM_TOPIC
      expect(state["m.room.create"]).not.to be_nil
      expect(state["m.room.name"][:content][:name]).to be == Async::Matrix::TEST_ROOM_NAME
    end

    it "returns nil for absent state" do
      expect(room.get_room_state["m.room.avatar"]).to be_nil
    end
  end

  with "#joined_members" do
    it "lists the creator" do
      expect(room.get_joined_members_by_room.user_ids).to be == [self.user_id]
    end
  end

  with "#send_message" do
    it "returns the event id" do
      sent = room.send_message("m.room.message", {msgtype: "m.text", body: "hello"})

      expect(sent.event_id).to be =~ /\A\$/
    end

    it "is idempotent for the same transaction id" do
      transaction_id = Async::Matrix::ClientServer::Room.transaction_id
      content = {msgtype: "m.text", body: "once"}

      first = room.send_message("m.room.message", content, transaction_id: transaction_id)
      again = room.send_message("m.room.message", content, transaction_id: transaction_id)

      expect(again.event_id).to be == first.event_id
    end
  end

  with "#messages" do
    it "can page backwards through the timeline" do
      3.times{|index| room.send_message("m.room.message", {msgtype: "m.text", body: "page #{index}"})}

      first = room.get_room_events(limit: 2)

      expect(first.events.size).to be == 2
      expect(first.finish).not.to be_nil

      following = first.following

      expect(following).to be_a(Async::Matrix::ClientServer::Messages)
      expect(following.events.size).to be == 2

      # The following page continues from where the first one ended:
      expect(following.start).to be == first.finish
    end

    it "includes the messages which were sent" do
      room.send_message("m.room.message", {msgtype: "m.text", body: "findable"})

      bodies = room.get_room_events(limit: 20).filter_map{|event| event.dig(:content, :body)}

      expect(bodies).to be(:include?, "findable")
    end
  end

  with "a second user" do
    let(:other_username) {"other-#{SecureRandom.hex(6)}"}
    let(:other) {unauthenticated.logged_in(other_username, Async::Matrix::TEST_PASSWORD)}

    it "can join and leave a public room" do
      public_room = client.create_room(preset: "public_chat")

      joined = other.join_room(public_room.id)

      expect(joined.id).to be == public_room.id
      expect(other.get_joined_rooms).to be(:include?, public_room.id)
      expect(public_room.get_joined_members_by_room.user_ids.size).to be == 2

      joined.leave_room

      expect(other.get_joined_rooms).not.to be(:include?, public_room.id)
    end
  end
end
