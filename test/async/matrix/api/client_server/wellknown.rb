# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/wellknown"

describe Async::Matrix::ClientServer::Wellknown do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  #
  # No authentication is required: this is what a client reads before it has any.
  it "can getWellknown" do
    discovery = unauthenticated.wellknown.get_wellknown

    expect(discovery.base_url).to be_a(String)
    expect(discovery.homeserver).to be(:include?, :base_url)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Wellknown::CASES
end
