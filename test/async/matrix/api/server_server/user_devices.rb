# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/server_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/server_server/user_devices"

describe Async::Matrix::ServerServer::UserDevices do
  include Async::Matrix::ServerContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ServerServer::UserDevices::CASES
end
