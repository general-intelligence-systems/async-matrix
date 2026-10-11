# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Tags do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can setRoomTag" do
    expect(client.tags.set_room_tag(self.user_id, room.id, "m.favourite", order: 0.5).value).to be == {}
  end

  it "can getRoomTags" do
    client.tags.set_room_tag(self.user_id, room.id, "m.favourite", order: 0.5)

    tags = client.tags.get_room_tags(self.user_id, room.id)

    expect(tags.names).to be(:include?, :"m.favourite")
    expect(tags.tags[:"m.favourite"]).to be == {order: 0.5}
  end

  it "can deleteRoomTag" do
    client.tags.set_room_tag(self.user_id, room.id, "m.favourite")

    expect(client.tags.delete_room_tag(self.user_id, room.id, "m.favourite").value).to be == {}
    expect(client.tags.get_room_tags(self.user_id, room.id)).to be(:empty?)
  end

  it "has no tags on a room which was never tagged" do
    expect(client.tags.get_room_tags(self.user_id, room.id)).to be(:empty?)
  end
end
