# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/versions"

describe Async::Matrix::ClientServer::SupportedVersions do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can getVersions" do
    versions = client.supported_versions.get_versions

    expect(versions.versions).to be(:include?, Async::Matrix::TEST_VERSION)
    expect(versions.unstable_features).to be_a(Hash)
  end

  it "says which versions it implements" do
    expect(client.supported_versions.get_versions).to be(:supports?, Async::Matrix::TEST_VERSION)
  end

  # The client offers the short way to ask, which is the same request.
  it "is what the client asks for its versions" do
    expect(client.versions.versions).to be(:include?, Async::Matrix::TEST_VERSION)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::SupportedVersions::CASES
end
