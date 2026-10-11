# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix"

describe Async::Matrix::Representation do
  it "wraps responses with the Matrix wrapper" do
    expect(subject::WRAPPER).to be_a(Async::Matrix::Wrapper)
  end

  with "#events" do
    it "inflates at the version the representation was built for" do
      sync = Async::Matrix::Versions["v1.15"]::Sync.new(nil)

      expect(sync.events).to be_equal(Async::Matrix::Events.registry("v1.15"))
    end

    it "inflates with the unversioned classes when there is no version" do
      sync = Async::Matrix::ClientServer::Sync.new(nil)

      expect(sync.events).to be_equal(Async::Matrix::Events.registry)
    end
  end
end
