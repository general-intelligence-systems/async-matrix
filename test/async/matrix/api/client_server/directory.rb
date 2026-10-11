# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/directory"

describe Async::Matrix::ClientServer::Directory do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # An alias of this case's own, since an alias is global to the homeserver.
  let(:room_alias) {"#test-#{SecureRandom.hex(6)}:localhost"}

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can setRoomAlias" do
    expect(client.directory.set_room_alias(room_alias, room.id).value).to be == {}
  end

  it "can getRoomIdByAlias" do
    client.directory.set_room_alias(room_alias, room.id)

    target = client.directory.get_room_id_by_alias(room_alias)

    expect(target.room_id).to be == room.id
    expect(target.servers).to be(:include?, "localhost")
  end

  it "can getLocalAliases" do
    client.directory.set_room_alias(room_alias, room.id)

    expect(client.directory.get_local_aliases(room.id).aliases).to be(:include?, room_alias)
  end

  it "can deleteRoomAlias" do
    client.directory.set_room_alias(room_alias, room.id)

    expect(client.directory.delete_room_alias(room_alias).value).to be == {}

    expect do
      client.directory.get_room_id_by_alias(room_alias)
    end.to raise_exception(Async::Matrix::RequestError)
  end

  it "has no aliases for a room which was never named" do
    expect(client.directory.get_local_aliases(room.id)).to be(:empty?)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Directory::CASES
end
