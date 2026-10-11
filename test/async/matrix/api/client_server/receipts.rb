# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Receipts do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:sent) {room.send_message("m.room.message", {msgtype: "m.text", body: "read me"})}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can postReceipt" do
    expect(client.receipts.post_receipt(room.id, "m.read", sent.event_id).value).to be == {}
  end

  it "sends a private receipt, which the other members do not see" do
    expect(client.receipts.post_receipt(room.id, "m.read.private", sent.event_id).value).to be == {}
  end

  # A receipt may be for a thread rather than the room, which `main` names the room's own timeline.
  it "sends a receipt for a thread" do
    expect(client.receipts.post_receipt(room.id, "m.read", sent.event_id, thread_id: "main").value).to be == {}
  end
end
