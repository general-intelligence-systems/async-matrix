# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
end
