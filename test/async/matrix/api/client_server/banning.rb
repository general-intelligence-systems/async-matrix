# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/banning"

describe Async::Matrix::ClientServer::Banning do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # A second user, since these operations are about somebody else.
  let(:other_username) {"other-#{SecureRandom.hex(6)}"}

  let(:other_id) {"@#{self.other_username}:localhost"}

  let(:other) {self.account(self.other_username)}

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can ban" do
    expect(client.banning.ban(room.id, other_id, reason: "no reason at all").value).to be == {}
  end

  it "can unban" do
    client.banning.ban(room.id, other_id)

    expect(client.banning.unban(room.id, other_id, reason: "a change of heart").value).to be == {}
  end

  it "keeps a banned user out" do
    client.banning.ban(room.id, other_id)

    expect do
      other.room(room.id).join_room_by_id
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Banning::CASES
end
