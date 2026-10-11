# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/to_device"

describe Async::Matrix::ClientServer::ToDevice do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer, and the case needs no version of its own.
  it "can sendToDevice" do
    messages = {self.user_id => {"*" => {algorithm: "m.megolm.v1.aes-sha2", room_id: "!r:localhost"}}}

    expect(client.to_device.send_to_device("m.room_key", messages).value).to be_a(Hash)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::ToDevice::CASES
end
