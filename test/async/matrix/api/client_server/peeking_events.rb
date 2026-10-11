# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::PeekingEvents do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  #
  # The endpoint is the one the deprecated synchronisation used, and it needs a token to read from: the room's own initial sync has one.
  let(:token) {client.room_initial_sync.room_initial_sync(room.id).messages[:end]}

  it "can peekEvents" do
    events = client.peeking_events.peek_events(token, room_id: room.id, timeout: 0)

    expect(events.chunk).to be_a(Array)
    expect(events.start).to be_a(String)
  end

  # The token a page ends at is where the next one starts, and nothing has happened in between.
  it "answers with nothing after the page it just gave" do
    page = client.peeking_events.peek_events(token, room_id: room.id, timeout: 0)

    expect(client.peeking_events.peek_events(page.finish, room_id: room.id, timeout: 0)).to be(:empty?)
  end
end
