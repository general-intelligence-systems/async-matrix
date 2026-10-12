# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE do
  include Async::Matrix::E2EEContext

  # Not an exact list: E2EE::Vodozemac and the classes the binding defines appear once anything requires it, which this file deliberately does not.
  it "requires everything encryption needs" do
    required = [:CanonicalJSON, :Crypto, :Device, :Devices, :Machine, :Plaintext, :Store]

    expect(required - Async::Matrix::E2EE.constants).to be(:empty?)
  end

  # Requiring this one file is all a client needs to encrypt, which is what it is for.
  it "is all a client needs to publish its keys to a homeserver" do
    machine = self.machine_for(client)

    expect(publish(machine).count("signed_curve25519")).to be > 0
  end
end
