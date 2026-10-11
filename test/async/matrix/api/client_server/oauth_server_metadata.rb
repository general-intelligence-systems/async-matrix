# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/oauth_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/oauth_server_metadata"

# Only where the backend's rig runs an authorization server, which it says by leaving MATRIX_OAUTH_HOMESERVER empty where it does not: these operations are answered by a homeserver which delegates authentication, and a rig without one has nothing to ask.
unless Async::Matrix::OAUTH_HOMESERVER.empty?
  describe Async::Matrix::ClientServer::OAuthServerMetadata do
    include Async::Matrix::ClientContext
    include Async::Matrix::OAuthContext
    include Async::Matrix::OperationsContext

    # The homeserver which delegates authentication: the version rig serves its own login API instead, and answers this endpoint with a 404.
    let(:unauthenticated) {Async::Matrix::ClientServer::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::OAUTH_HOMESERVER)}

    let(:metadata) {unauthenticated.oauth_server_metadata.get_auth_metadata}

    # The cases for the operations themselves, layered by the version which introduced each:
    include Async::Matrix::Testing::Abstract::ClientServer::OAuthServerMetadata::CASES
  end
end
