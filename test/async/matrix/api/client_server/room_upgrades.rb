# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/room_upgrades"

describe Async::Matrix::ClientServer::RoomUpgrades do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, but the room version it can upgrade to is not, so the cases are layered:
  include Async::Matrix::Testing::Abstract::ClientServer::RoomUpgrades::CASES
end
