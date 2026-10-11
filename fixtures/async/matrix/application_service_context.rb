# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "sus/fixtures/async"

require "async/matrix"

require_relative "client_context"

module Async
  module Matrix
    # Where the application service is.
    #
    # The rig runs the stub in synapse/appservice-stub.py, which `bin/test --api application-service` brings up. Every bridge is a bridge to something, so there is no stock one to run: the stub owns one user, one alias and one protocol, which is enough for the operations.
    APPLICATION_SERVICE = ENV.fetch("MATRIX_APPLICATION_SERVICE", "http://localhost:7305")

    # The user the service owns, and the alias, which it answers for and nothing else.
    APPLICATION_SERVICE_USER = "@stub-user:localhost"

    APPLICATION_SERVICE_ALIAS = "#stub-room:localhost"

    APPLICATION_SERVICE_PROTOCOL = "stub"

    # Included by a test which exercises the application service API.
    #
    # The client is called `unauthenticated` because that is the name {OperationsContext} spies on to prove a case made a request.
    ApplicationServiceContext = Sus::Shared("an application service client") do
      include Sus::Fixtures::Async::ReactorContext

      let(:unauthenticated) {Async::Matrix::ApplicationService::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::APPLICATION_SERVICE)}

      # The token a homeserver carries is the one the registration gave it, which the stub does not check.
      let(:service) {unauthenticated.authenticated("a-homeserver-token")}
    end
  end
end
