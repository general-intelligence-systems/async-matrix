# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE do
  include Async::Matrix::E2EEContext

  it "requires everything encryption needs" do
    expect(Async::Matrix::E2EE.constants.sort).to be == [:CanonicalJSON, :Crypto, :Device, :Devices, :Machine, :Plaintext, :Store]
  end

  # Requiring this one file is all a client needs to encrypt, which is what it is for.
  it "is all a client needs to publish its keys to a homeserver" do
    machine = Async::Matrix::E2EE::Machine.new(client)

    expect(machine.publish!.count("signed_curve25519")).to be > 0
  end
end
