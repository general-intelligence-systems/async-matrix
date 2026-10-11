# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

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
end
