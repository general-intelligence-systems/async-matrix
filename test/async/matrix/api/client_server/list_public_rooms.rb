# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::ListPublicRooms do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can getPublicRooms" do
    rooms = client.list_public_rooms.get_public_rooms(limit: 5)

    expect(rooms.chunk).to be_a(Array)
    expect(rooms.total_room_count_estimate).to be_a(Integer)
  end

  it "can queryPublicRooms" do
    expect(client.list_public_rooms.query_public_rooms(limit: 5, filter: {generic_search_term: Async::Matrix::TEST_ROOM_NAME}).chunk).to be_a(Array)
  end

  it "can getRoomVisibilityOnDirectory" do
    visibility = client.list_public_rooms.get_room_visibility_on_directory(room.id)

    expect(visibility.visibility).to be == "private"
    expect(visibility).not.to be(:public?)
  end

  # The rig lets any room publish - see `room_list_publication_rules` in the homeserver configuration - so the room goes onto the directory and the entry which said it was private now says it is public.
  it "can setRoomVisibilityOnDirectory" do
    client.list_public_rooms.set_room_visibility_on_directory(room.id, "public")

    visibility = client.list_public_rooms.get_room_visibility_on_directory(room.id)

    expect(visibility.visibility).to be == "public"
    expect(visibility).to be(:public?)
  end
end
