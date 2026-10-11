# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee"

describe Async::Matrix::E2EE do
  it "requires everything encryption needs" do
    expect(Async::Matrix::E2EE.constants.sort).to be == [:CanonicalJSON, :Crypto, :Device, :Devices, :Machine, :Plaintext, :Store]
  end
end
