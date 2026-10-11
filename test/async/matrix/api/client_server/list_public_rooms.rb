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

  # Synapse keeps publication to itself by default, so the homeserver refuses. The case asserts the refusal: what it has to prove is that the request is the one the specification asked for.
  it "can setRoomVisibilityOnDirectory" do
    expect do
      client.list_public_rooms.set_room_visibility_on_directory(room.id, "public")
    end.to raise_exception(Async::Matrix::RequestError)
  end
end
