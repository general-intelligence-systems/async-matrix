# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/server_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/server_server/leaving_v1"

describe Async::Matrix::ServerServer::LeavingV1 do
  include Async::Matrix::ServerContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ServerServer::LeavingV1::CASES

  # The send the first version had, whose cases v1.18 withdrew along with it:
  include Async::Matrix::Testing::Abstract::ServerServer::SendLeaveV1::CASES
end
