# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/device"

describe Async::Matrix::E2EE::Device do
  # Exactly what `POST /keys/query` answers for one device.
  let(:value) do
    {
      algorithms: ["m.olm.v1.curve25519-aes-sha2", "m.megolm.v1.aes-sha2"],
      device_id: "JLAFKJWSCS",
      keys: {
        "curve25519:JLAFKJWSCS": "3C5BFWi2Y8MaVvjM8M22DBmh24PmgR0nPvJOIArzgyI",
        "ed25519:JLAFKJWSCS": "lEuiRJBit0IG6nUf5pUzWTUEsRVVe/HJkoKuEww9ULI",
      },
      signatures: {
        "@alice:localhost": {
          "ed25519:JLAFKJWSCS": "dSO80A01XiigH3uBiDVx/EjzaoycHcjq9lfQX0uWsqxl2giMIiSPR8a4d291W1ihKJL/a+myXS367WT6NAIcBA",
        },
      },
      unsigned: {device_display_name: "Alice's mobile phone"},
    }
  end

  let(:device) {subject.new("@alice:localhost", "JLAFKJWSCS", value)}

  with "#curve25519" do
    # The keys are published under a name which includes the device, so reading one means knowing which device it belongs to.
    it "reads the key its own device published" do
      expect(device.curve25519).to be == "3C5BFWi2Y8MaVvjM8M22DBmh24PmgR0nPvJOIArzgyI"
      expect(device.ed25519).to be == "lEuiRJBit0IG6nUf5pUzWTUEsRVVe/HJkoKuEww9ULI"
    end

    it "answers nothing for a device which published no keys" do
      bare = subject.new("@alice:localhost", "OTHER", {})

      expect(bare.curve25519).to be_nil
      expect(bare.ed25519).to be_nil
      expect(bare.keys).to be == {}
      expect(bare.algorithms).to be == []
      expect(bare.signatures).to be == {}
      expect(bare.display_name).to be_nil
    end
  end

  with "#display_name" do
    it "reads the name its owner gave it" do
      expect(device.display_name).to be == "Alice's mobile phone"
    end
  end

  with "#supports?" do
    it "answers whether the device can encrypt with an algorithm" do
      expect(device).to be(:supports?, "m.megolm.v1.aes-sha2")
      expect(device).not.to be(:supports?, "m.made.up")
    end
  end

  with "#trust" do
    # A device is trusted by its owner's user, never by this library, so it begins untrusted.
    it "is unverified until someone says otherwise" do
      expect(device.trust).to be == :unverified
      expect(device).not.to be(:verified?)
      expect(device).not.to be(:blocked?)
    end

    it "is verified once its owner vouches for it" do
      device.trust = :verified

      expect(device).to be(:verified?)
      expect(device).not.to be(:blocked?)
    end

    it "is blocked once its owner refuses it" do
      device.trust = :blocked

      expect(device).to be(:blocked?)
      expect(device).not.to be(:verified?)
    end

    it "declares the trust a device can be given" do
      expect(subject::TRUST).to be == [:unverified, :verified, :blocked]
    end
  end

  with "#==" do
    # A device is the same device when it is the same device of the same user, whatever its keys say now.
    it "is the same device when the user and the device agree" do
      expect(device).to be == subject.new("@alice:localhost", "JLAFKJWSCS", {})
    end

    it "is a different device when either differs" do
      expect(device).not.to be == subject.new("@bob:localhost", "JLAFKJWSCS", value)
      expect(device).not.to be == subject.new("@alice:localhost", "OTHER", value)
    end

    it "is not anything which is not a device" do
      expect(device).not.to be == "@alice:localhost"
    end
  end
end
