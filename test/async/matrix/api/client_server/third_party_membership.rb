# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::ThirdPartyMembership do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  #
  # Resolving the address is the identity server's to do, and the rig has none, so the homeserver fails rather than refuses. The case asserts no more than that the request reached it.
  it "can inviteBy3PID" do
    expect do
      client.third_party_membership.invite_by_3pid(room.id, "localhost", "not-a-token", "email", "nobody@example.com")
    end.to raise_exception(Async::Matrix::RequestError)
  end
end
