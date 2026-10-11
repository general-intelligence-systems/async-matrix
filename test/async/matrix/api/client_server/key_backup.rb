# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/key_backup"

describe Async::Matrix::ClientServer::KeyBackup do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::KeyBackup::CASES

  # The session operations, which v1.2 renamed:
  include Async::Matrix::Testing::Abstract::ClientServer::BackupKeys::CASES
end
