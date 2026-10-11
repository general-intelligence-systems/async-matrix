# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::RoomUpgrades do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can upgradeRoom" do
    expect(client.room_upgrades.upgrade_room(room.id, "11").replacement_room).to be =~ /\A!/
  end

  # The replacement is a room of its own, which this user is joined to.
  it "answers with a room which is not the one upgraded" do
    replacement = client.room_upgrades.upgrade_room(room.id, "11").replacement_room

    expect(replacement).not.to be == room.id
    expect(client.get_joined_rooms.ids).to be(:include?, replacement)
  end
end
