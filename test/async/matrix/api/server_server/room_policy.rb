# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/server_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/server_server/room_policy"

describe Async::Matrix::ServerServer::RoomPolicy do
  include Async::Matrix::ServerContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ServerServer::RoomPolicy::CASES
end
