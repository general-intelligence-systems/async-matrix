# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/device"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Device do
  include Async::Matrix::E2EEContext

  # The other user's device, exactly as `POST /keys/query` answered with it.
  let(:device) do
    other_machine.publish!

    machine.devices.of(other_user_id).first
  end

  with "#curve25519" do
    # The keys are published under a name which includes the device, so reading one means knowing which device it belongs to.
    it "reads the keys that device published" do
      expect(device.curve25519).to be == other_crypto.identity_keys[:curve25519]
      expect(device.ed25519).to be == other_crypto.identity_keys[:ed25519]
    end

    it "says which user and device it belongs to" do
      expect(device.user_id).to be == other_user_id
      expect(device.device_id).to be == other_device_id
    end

    it "answers nothing for a device which published no keys" do
      bare = machine.devices.of(other_user_id)

      expect(bare).to be(:empty?)
    end
  end

  with "#display_name" do
    it "reads the name its owner gave it" do
      other_machine.publish!
      other.devices.update(other_device_id, display_name: "Other's phone")

      expect(machine.devices.of(other_user_id).first.display_name).to be == "Other's phone"
    end
  end

  with "#supports?" do
    it "answers whether the device can encrypt with an algorithm" do
      expect(device).to be(:supports?, Async::Matrix::E2EE::Machine::MEGOLM)
      expect(device).not.to be(:supports?, "m.made.up")
      expect(device.algorithms).to be == other_crypto.algorithms
    end
  end

  with "#signatures" do
    # A device is trusted because of the signature it carries, so the signature must survive the round trip.
    it "carries a signature which verifies against its own key" do
      signature = device.signatures[other_user_id.to_sym][:"ed25519:#{other_device_id}"]

      expect(other_crypto.verify(device.value, key: device.ed25519, signature: signature)).to be == true
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
      expect(device).to be == subject.new(other_user_id, other_device_id, {})
    end

    it "is a different device when either differs" do
      expect(device).not.to be == subject.new(user_id, other_device_id, device.value)
      expect(device).not.to be == subject.new(other_user_id, "OTHER", device.value)
      expect(device).not.to be == other_user_id
    end
  end
end
