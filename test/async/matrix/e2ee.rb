# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE do
  include Async::Matrix::E2EEContext

  # Not an exact list: the point is that one require is enough, not that this is all there is.
  it "requires everything encryption needs" do
    required = [
      :Backup, :CanonicalJSON, :CrossSigning, :Crypto, :Device, :Devices,
      :Machine, :Olm, :Plaintext, :Secrets, :SecretStorage, :Store,
    ]

    expect(required - Async::Matrix::E2EE.constants).to be(:empty?)
  end

  # Requiring this one file is all a client needs to encrypt, which is what it is for.
  it "is all a client needs to publish its keys to a homeserver" do
    machine = self.machine_for(client)

    expect(publish(machine).count("signed_curve25519")).to be > 0
  end
end
