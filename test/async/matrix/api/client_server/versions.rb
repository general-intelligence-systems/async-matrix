# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/versions"

describe Async::Matrix::ClientServer::SupportedVersions do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  #
  # What the homeserver answers with is its own, so the version it names is asserted by the layer below rather than here.
  it "can getVersions" do
    versions = client.supported_versions.get_versions

    expect(versions.versions).not.to be(:empty?)
    expect(versions.unstable_features).to be_a(Hash)
  end

  # The cases which read the version under test out of the answer, for as long as a homeserver names it:
  include Async::Matrix::Testing::Abstract::ClientServer::SupportedVersions::CASES
end
