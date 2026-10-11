# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/read_markers"

describe Async::Matrix::ClientServer::ReadMarkers do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:sent) {room.send_message("m.room.message", {msgtype: "m.text", body: "read me"})}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can setReadMarker" do
    expect(client.read_markers.set_read_marker(room.id, fully_read: sent.event_id).value).to be == {}
  end

  # The marker and the public receipt are set together, which is the point of the endpoint.
  it "sets the receipt along with the marker" do
    expect(client.read_markers.set_read_marker(room.id, fully_read: sent.event_id, read: sent.event_id).value).to be == {}
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::ReadMarkers::CASES
end
