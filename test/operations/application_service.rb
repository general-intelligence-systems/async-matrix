# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/api_context"

# What the application_service API owes: a namespace, a class per concept the schemas name, a method per operation, and no method for an operation the version under test does not define.
describe Async::Matrix do
  include Async::Matrix::ApiContext.for("application_service")
end
