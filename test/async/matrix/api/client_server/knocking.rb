# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Knocking do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # A room which can be knocked on, which is a room whose join rule says so.
  let(:knockable) do
    client.create_room(name: Async::Matrix::TEST_ROOM_NAME, initial_state: [{type: "m.room.join_rules", state_key: "", content: {join_rule: "knock"}}])
  end

  let(:knocker) {unauthenticated.logged_in("other-#{SecureRandom.hex(6)}", Async::Matrix::TEST_PASSWORD)}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can knockRoom" do
    expect(knocker.knocking.knock_room(knockable.id, reason: "let me in").room_id).to be == knockable.id
  end

  it "knocks through the servers it is given" do
    expect(knocker.knocking.knock_room(knockable.id, via: ["localhost"]).room_id).to be == knockable.id
  end

  # A room nobody may knock on refuses, which is the homeserver reading the join rule rather than this.
  it "is refused where the join rule does not allow it" do
    expect do
      knocker.knocking.knock_room(room.id)
    end.to raise_exception(Async::Matrix::RequestError)
  end
end
