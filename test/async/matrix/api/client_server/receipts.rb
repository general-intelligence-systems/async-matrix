# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/receipts"

describe Async::Matrix::ClientServer::Receipts do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:sent) {room.send_message("m.room.message", {msgtype: "m.text", body: "read me"})}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can postReceipt" do
    expect(client.receipts.post_receipt(room.id, "m.read", sent.event_id).value).to be == {}
  end

  # The private receipt and the thread arrived in v1.4, so those cases are in that layer:
  include Async::Matrix::Testing::Abstract::ClientServer::Receipts::CASES
end
