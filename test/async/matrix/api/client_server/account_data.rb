# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/account_data"

describe Async::Matrix::ClientServer::AccountData do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # A type of this test's own, since the homeserver keeps whatever it is given under whatever type.
  let(:type) {"com.example.async_matrix"}

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can setAccountData" do
    expect(client.account_data.set_account_data(self.user_id, type, {colour: "blue"}).value).to be == {}
  end

  it "can getAccountData" do
    client.account_data.set_account_data(self.user_id, type, {colour: "blue"})

    expect(client.account_data.get_account_data(self.user_id, type).value).to be == {colour: "blue"}
  end

  it "can setAccountDataPerRoom" do
    expect(client.account_data.set_account_data_per_room(self.user_id, room.id, type, {colour: "green"}).value).to be == {}
  end

  it "can getAccountDataPerRoom" do
    client.account_data.set_account_data_per_room(self.user_id, room.id, type, {colour: "green"})

    expect(client.account_data.get_account_data_per_room(self.user_id, room.id, type).value).to be == {colour: "green"}
  end

  # The two are stored apart, so the room's data does not answer for the account's.
  it "keeps the data of a room apart from the data of the account" do
    client.account_data.set_account_data(self.user_id, type, {colour: "blue"})
    client.account_data.set_account_data_per_room(self.user_id, room.id, type, {colour: "green"})

    expect(client.account_data.get_account_data(self.user_id, type).value).to be == {colour: "blue"}
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::AccountData::CASES
end
