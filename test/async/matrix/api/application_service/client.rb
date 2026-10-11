# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/application_service_context"

require_relative "../../abstract/api/application_service/client"

describe Async::Matrix::ApplicationService::Client do
  include Async::Matrix::ApplicationServiceContext

  it "is built for the version it was asked for" do
    expect(subject[Async::Matrix::TEST_VERSION].version).to be == Async::Matrix::TEST_VERSION
  end

  it "is layered from the application service namespace" do
    expect(subject.namespace).to be_equal(Async::Matrix::ApplicationService)
  end

  # The token is the one the registration gave the homeserver, which the service checks.
  it "carries the token it was given" do
    expect(service.headers["authorization"]).to be == "Bearer a-homeserver-token"
  end

  # The cases for the navigators, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ApplicationService::Client::CASES
end
