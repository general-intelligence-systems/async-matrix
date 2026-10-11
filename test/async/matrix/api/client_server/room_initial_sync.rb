# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/room_initial_sync"

describe Async::Matrix::ClientServer::RoomInitialSync do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can roomInitialSync" do
    snapshot = client.room_initial_sync.room_initial_sync(room.id)

    expect(snapshot.room_id).to be == room.id
    expect(snapshot.membership).to be == "join"
  end

  it "answers with the state and the recent events together" do
    room.send_message("m.room.message", {msgtype: "m.text", body: "recent"})

    snapshot = client.room_initial_sync.room_initial_sync(room.id)

    expect(snapshot.state).not.to be(:empty?)
    expect(snapshot.messages[:chunk]).to be_a(Array)
    expect(snapshot.account_data).to be_a(Array)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::RoomInitialSync::CASES
end
