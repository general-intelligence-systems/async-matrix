# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/refresh"

describe Async::Matrix::ClientServer::Refresh do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # Asked for explicitly: `#login` does not request one by default, because it shortens the access token.
  let(:login) {unauthenticated.login(username, Async::Matrix::TEST_PASSWORD, refresh_token: true)}

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Refresh::CASES
end
