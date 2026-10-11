# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/paths"

describe Async::Matrix do
  # The API is versioned per-endpoint, so a path is absolute and replaces the resource path.
  it "names the versioned base paths" do
    expect(Async::Matrix::V1).to be == "/_matrix/client/v1"
    expect(Async::Matrix::V3).to be == "/_matrix/client/v3"
    expect(Async::Matrix::MEDIA_V3).to be == "/_matrix/media/v3"
  end

  it "gives paths which replace rather than extend" do
    [Async::Matrix::V1, Async::Matrix::V3, Async::Matrix::MEDIA_V3].each do |path|
      expect(path).to be(:start_with?, "/")
    end
  end

  # The server-server API is versioned per-endpoint too, and its keys and policies are not under `federation`.
  it "names the server-server base paths" do
    expect(Async::Matrix::FEDERATION_V1).to be == "/_matrix/federation/v1"
    expect(Async::Matrix::FEDERATION_V2).to be == "/_matrix/federation/v2"
    expect(Async::Matrix::KEY_V2).to be == "/_matrix/key/v2"
    expect(Async::Matrix::POLICY_V1).to be == "/_matrix/policy/v1"
  end

  it "gives server-server paths which replace rather than extend" do
    [Async::Matrix::FEDERATION_V1, Async::Matrix::FEDERATION_V2, Async::Matrix::KEY_V2, Async::Matrix::POLICY_V1].each do |path|
      expect(path).to be(:start_with?, "/")
    end
  end
end
