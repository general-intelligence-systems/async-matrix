# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/application_service_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/application_service/ping"

describe Async::Matrix::ApplicationService::Ping do
  include Async::Matrix::ApplicationServiceContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ApplicationService::Ping::CASES
end
