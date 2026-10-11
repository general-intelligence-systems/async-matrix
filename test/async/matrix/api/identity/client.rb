# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identity_context"

describe Async::Matrix::Identity::Client do
  include Async::Matrix::IdentityContext

  it "is built for the version it was asked for" do
    expect(subject[Async::Matrix::TEST_VERSION].version).to be == Async::Matrix::TEST_VERSION
  end

  it "resolves its peers at its own version" do
    client = subject[Async::Matrix::TEST_VERSION]

    expect(client.api::V2Auth).to be_equal(Async::Matrix::Versions[Async::Matrix::TEST_VERSION, Async::Matrix::Identity]::V2Auth)
  end

  # The identity API is a server of its own, so its namespace is layered on its own too.
  it "is layered from the identity namespace rather than the client-server one" do
    expect(subject.namespace).to be_equal(Async::Matrix::Identity)
  end

  it "carries the user agent" do
    expect(unauthenticated.headers["user-agent"]).to be(:include?, "async-matrix")
  end

  # The token an identity server issues is its own, and goes in the header rather than below the resource.
  it "carries the token it was given" do
    expect(identity.headers["authorization"]).to be =~ /\ABearer \S+\z/
  end
end
