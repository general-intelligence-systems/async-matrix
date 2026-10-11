# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/api_context"

# What the server_server API owes: a namespace, a class per concept the schemas name, a method per operation, and no method for an operation the version under test does not define.
describe Async::Matrix do
  include Async::Matrix::ApiContext.for("server_server")
end
