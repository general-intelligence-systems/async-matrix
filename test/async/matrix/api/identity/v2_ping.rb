# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/v2_ping"

describe Async::Matrix::Identity::V2Ping do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # No authentication is required: this is what a client asks before it has an account.
  it "can pingV2" do
    expect(unauthenticated.v2_ping.ping_v2.value).to be == {}
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::V2Ping::CASES
end
