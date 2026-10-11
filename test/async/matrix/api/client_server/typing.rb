# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Typing do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer, and the case needs no version of its own.
  it "can setTyping" do
    expect(client.typing.set_typing(room.id, self.user_id, true, timeout: 5000).value).to be == {}
  end

  it "says the user has stopped" do
    expect(client.typing.set_typing(room.id, self.user_id, false).value).to be == {}
  end

  it "escapes the room and the user in the path" do
    path = Async::Matrix::ClientServer::Typing.path_for("!a room:localhost", "@a user:localhost")

    expect(path).to be == "#{Async::Matrix::V3}/rooms/%21a%20room%3Alocalhost/typing/%40a%20user%3Alocalhost"
  end
end
