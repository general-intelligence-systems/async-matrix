# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/appservice_room_directory"

describe Async::Matrix::ClientServer::AppserviceRoomDirectory do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  #
  # Only the application service which bridges the network may publish its rooms, and the rig runs none, so the homeserver refuses. The case asserts that refusal: what it proves is that the request is the one the specification describes, and that it reached the homeserver.
  it "can updateAppserviceRoomDirectoryVisibility" do
    error = nil

    begin
      client.appservice_room_directory.update_appservice_room_directory_visibility("a-network", room.id, "public")
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_FORBIDDEN"
  end

  it "escapes the network and the room in the path" do
    path = Async::Matrix::ClientServer::AppserviceRoomDirectory.path_for("a network", "!a room:localhost")

    expect(path).to be == "#{Async::Matrix::V3}/directory/list/appservice/a%20network/%21a%20room%3Alocalhost"
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::AppserviceRoomDirectory::CASES
end
