# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/push_gateway_context"

describe Async::Matrix::PushGateway::Client do
  include Async::Matrix::PushGatewayContext

  it "is built for the version it was asked for" do
    expect(subject[Async::Matrix::TEST_VERSION].version).to be == Async::Matrix::TEST_VERSION
  end

  # The push gateway API is a server of its own, so its namespace is layered on its own too.
  it "is layered from the push gateway namespace" do
    expect(subject.namespace).to be_equal(Async::Matrix::PushGateway)
  end

  it "carries the user agent" do
    expect(unauthenticated.headers["user-agent"]).to be(:include?, "async-matrix")
  end
end
