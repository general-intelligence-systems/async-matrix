# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/device"
require "async/matrix/signatures/keyring"

describe Async::Matrix::Signatures::Keyring do
  let(:keyring) {subject.new}

  # A key of the algorithm the specification defines, which is the appendices' own.
  KEY = "XSl0kuyvrXNj6A+7/tkrB9sxSbRi08Of5uRhxOqZtEQ"

  with "#add" do
    it "holds a key by entity and signing key identifier" do
      keyring.add("example.org", "ed25519:1", KEY)

      expect(keyring.verification_key("example.org", "ed25519:1").encoded).to be == KEY
    end

    it "takes the identifier and the entity as symbols too" do
      keyring.add(:"example.org", :"ed25519:1", KEY)

      expect(keyring.verification_key("example.org", "ed25519:1")).not.to be_nil
    end

    # There is nothing to check a curve25519 signature with, so holding the key would be a lie.
    it "does not hold a key whose algorithm cannot check a signature" do
      keyring.add("example.org", "curve25519:1", "F8QhZ0Z1rjtWrQOblMDgZtEX5x1UrG7sZ2Kk3xliNAU")

      expect(keyring["example.org"]).to be == {}
    end

    it "can be chained, so a keyring is built in one expression" do
      expect(keyring.add("a", "ed25519:1", KEY).add("b", "ed25519:1", KEY).entities).to be == ["a", "b"]
    end
  end

  with "#verification_key" do
    it "answers nothing for an entity it holds no key for" do
      expect(keyring.verification_key("example.org", "ed25519:1")).to be_nil
    end

    it "answers nothing for a key identifier it does not hold" do
      keyring.add("example.org", "ed25519:1", KEY)

      expect(keyring.verification_key("example.org", "ed25519:2")).to be_nil
    end
  end

  with ".for_device" do
    let(:value) do
      {
        user_id: "@alice:example.com",
        device_id: "DEVICE",
        keys: {
          :"curve25519:DEVICE" => "F8QhZ0Z1rjtWrQOblMDgZtEX5x1UrG7sZ2Kk3xliNAU",
          :"ed25519:DEVICE" => "n469gw7zm+KW+JsFIJKnFVvCKU14HwQyocggcCIQgZY",
        },
      }
    end

    # A device's keys are signed by the user who owns it, so the user is the entity.
    it "holds the device's signing key under its owner" do
      expect(subject.for_device(value)["@alice:example.com"].keys).to be == ["ed25519:DEVICE"]
    end

    it "reads a device object as readily as the keys the server answered with" do
      device = Async::Matrix::E2EE::Device.new("@alice:example.com", "DEVICE", value)

      expect(subject.for_device(device).verification_key("@alice:example.com", "ed25519:DEVICE")).not.to be_nil
    end
  end

  with ".for_server" do
    let(:value) do
      {
        server_name: "example.org",
        verify_keys: {:"ed25519:1" => {key: KEY}},
        old_verify_keys: {:"ed25519:0" => {key: KEY, expired_ts: 922834800000}},
      }
    end

    it "holds the keys a server publishes for itself" do
      expect(subject.for_server(value)["example.org"].keys.sort).to be == ["ed25519:0", "ed25519:1"]
    end

    # A signature made before a key was rotated away from is still a signature it made.
    it "leaves out the rotated keys when asked to" do
      expect(subject.for_server(value, expired: false)["example.org"].keys).to be == ["ed25519:1"]
    end
  end
end
