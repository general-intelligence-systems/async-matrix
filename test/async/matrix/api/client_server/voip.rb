# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/voip"

describe Async::Matrix::ClientServer::VOIP do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  #
  # The rig has no TURN server, so the homeserver answers with no URIs rather than refusing.
  it "can getTurnServer" do
    turn = client.voip.get_turn_server

    expect(turn.uris).to be_a(Array)
    expect(turn.uris).to be(:empty?)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::VOIP::CASES
end
