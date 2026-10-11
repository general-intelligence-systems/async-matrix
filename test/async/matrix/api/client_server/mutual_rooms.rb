# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::MutualRooms do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext
end
