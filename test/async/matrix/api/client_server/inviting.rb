# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/inviting"

describe Async::Matrix::ClientServer::Inviting do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # A second user, since these operations are about somebody else.
  let(:other_username) {"other-#{SecureRandom.hex(6)}"}

  let(:other_id) {"@#{self.other_username}:localhost"}

  let(:other) {self.account(self.other_username)}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can inviteUser" do
    expect(client.inviting.invite_user(room.id, other_id, reason: "come in").value).to be == {}
  end

  it "lets the invited user join" do
    client.inviting.invite_user(room.id, other_id)

    expect(other.room(room.id).join_room_by_id.room_id).to be == room.id
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Inviting::CASES
end
