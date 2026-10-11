# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/versions"

describe Async::Matrix::Identity::SupportedVersions do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  it "can getVersions" do
    versions = unauthenticated.supported_versions.get_versions

    expect(versions.versions).not.to be(:empty?)
    expect(versions).to be(:supports?, "v1.1")
  end

  # The identity API is versioned on its own, so the server does not advertise the client-server versions this suite is run for.
  it "advertises the identity versions rather than the client-server ones" do
    expect(unauthenticated.supported_versions.get_versions.versions).to be(:include?, "r0.1.0")
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::SupportedVersions::CASES
end
