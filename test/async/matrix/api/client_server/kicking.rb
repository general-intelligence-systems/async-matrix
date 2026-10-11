# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/kicking"

describe Async::Matrix::ClientServer::Kicking do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # A second user, since these operations are about somebody else.
  let(:other_username) {"other-#{SecureRandom.hex(6)}"}

  let(:other_id) {"@#{self.other_username}:localhost"}

  let(:other) {self.account(self.other_username)}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can kick" do
    client.inviting.invite_user(room.id, other_id)
    other.room(room.id).join_room_by_id

    expect(client.kicking.kick(room.id, other_id, reason: "that is enough").value).to be == {}
  end

  # A kick is not a ban, so the user may come back.
  it "lets a kicked user join again" do
    client.inviting.invite_user(room.id, other_id)
    other.room(room.id).join_room_by_id
    client.kicking.kick(room.id, other_id)

    expect(client.inviting.invite_user(room.id, other_id).value).to be == {}
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Kicking::CASES
end
