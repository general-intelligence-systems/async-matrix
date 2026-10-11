# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/old_sync"

describe Async::Matrix::ClientServer::OldSync do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:sent) {room.send_message("m.room.message", {msgtype: "m.text", body: "before the sync"})}

  # The operations are in every version, so the methods are on the class rather than in a layer.
  #
  # The specification deprecated all three in favour of `/sync`, and Synapse still answers them.
  it "can initialSync" do
    sent

    synced = client.old_sync.initial_sync(limit: 1)

    expect(synced.rooms.size).to be == 1
    expect(synced.finish).to be_a(String)
    expect(synced.account_data).to be_a(Array)
  end

  it "can getEvents" do
    page = client.old_sync.get_events(timeout: 0)

    expect(page.chunk).to be_a(Array)
    expect(page.start).to be_a(String)
  end

  it "can getOneEvent" do
    expect(client.old_sync.get_one_event(sent.event_id).type).to be == "m.room.message"
  end

  it "takes the rooms this user has left where it is asked to" do
    expect(client.old_sync.initial_sync(limit: 1, archived: true).rooms).to be_a(Array)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::OldSync::CASES
end
