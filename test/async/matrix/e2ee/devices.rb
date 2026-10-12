# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/devices"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Devices do
  include Async::Matrix::E2EEContext

  let(:devices) {machine.devices}

  with "#accept" do
    it "takes on the devices the homeserver named" do
      publish(other_machine, as: other)

      self.accept_devices([other_user_id])

      expect(devices.of(other_user_id).map(&:device_id)).to be == [other_device_id]
    end

    it "builds a device from what the other user published" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      device = devices.of(other_user_id).first

      expect(device).to be_a(Async::Matrix::E2EE::Device)
      expect(device.user_id).to be == other_user_id
      expect(device.curve25519).to be == other_crypto.identity_keys[:curve25519]
    end

    # A user is only encrypted to once they have published keys, and until then the homeserver answers with nothing.
    it "notes a user with no devices, so they are not asked about again" do
      self.accept_devices([other_user_id])

      expect(devices).not.to be(:stale?, other_user_id)
      expect(devices.of(other_user_id)).to be == []
    end

    it "answers every device the other user has published" do
      publish(other_machine, as: other)

      second = self.account(other_username)
      publish(self.machine_for(second, crypto: Async::Matrix::E2EE::Plaintext.new), as: second)

      self.accept_devices([other_user_id])

      expect(devices.of(other_user_id).map(&:device_id).sort).to be == [other_device_id, second.get_token_owner.device_id].sort
    end
  end

  with "#stale?" do
    # A user nothing is known about has to be queried, which is the same as having been invalidated.
    it "says a user it has never heard of must be queried" do
      expect(devices).to be(:stale?, other_user_id)
    end

    # Nothing here reaches the homeserver, so what it holds is what it was last told and no more.
    it "answers what it was told, however stale the homeserver says it is" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      other.devices.update_device(other_device_id, display_name: "Renamed")

      expect(devices.of(other_user_id).first.display_name).to be_nil
    end
  end

  with "#invalidate" do
    # Sync reports that a user's devices changed, never what they changed to, so the only answer is to ask again.
    it "marks a user whose devices changed, and takes the new answer on" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      other.devices.update_device(other_device_id, display_name: "Renamed")
      devices.invalidate(changed: [other_user_id])

      expect(devices).to be(:stale?, other_user_id)
      expect(devices.querying).to be(:include?, other_user_id)

      self.accept_devices([other_user_id])

      expect(devices.of(other_user_id).first.display_name).to be == "Renamed"
    end

    it "forgets a user who is gone" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      devices.invalidate(left: [other_user_id])

      expect(devices.devices).not.to be(:key?, other_user_id)
    end
  end

  with "#track" do
    # Sharing an encrypted room with somebody is what makes their devices worth following.
    it "follows a user from now on, and wants them queried" do
      devices.track(other_user_id)

      expect(devices.tracking).to be == [other_user_id]
      expect(devices).to be(:stale?, other_user_id)
    end

    it "stops following a user who is gone" do
      devices.track(other_user_id)
      devices.invalidate(left: [other_user_id])

      expect(devices.tracking).to be == []
    end
  end

  with "#by_curve25519" do
    # An Olm message names its sender by the key it was encrypted with, so that is what a device is found by.
    it "finds the device which holds an identity key" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      device = devices.by_curve25519(other_user_id, other_crypto.identity_keys[:curve25519])

      expect(device.device_id).to be == other_device_id
    end

    it "finds nothing for a key that user does not hold" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      expect(devices.by_curve25519(other_user_id, crypto.identity_keys[:curve25519])).to be_nil
    end
  end

  with "#verified?" do
    it "says a device nothing is known about is not verified" do
      expect(devices).not.to be(:verified?, other_user_id, other_device_id)
    end

    it "says a device is verified once it has been" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      expect(devices).not.to be(:verified?, other_user_id, other_device_id)

      devices.of(other_user_id).first.trust = :verified

      expect(devices).to be(:verified?, other_user_id, other_device_id)
      expect(devices.verified_of(other_user_id).map(&:device_id)).to be == [other_device_id]
    end
  end

  with "#recipients" do
    it "answers every device of every user it was given" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      expect(devices.recipients([other_user_id]).map(&:device_id)).to be == [other_device_id]
    end

    # A device does not send a room key to itself, because it already has the session.
    it "leaves out a device of our own" do
      publish(machine)
      self.accept_devices([user_id])

      expect(devices.recipients([user_id], except: machine.device_id)).to be == []
      expect(devices.recipients([user_id]).map(&:device_id)).to be == [machine.device_id]
    end

    it "leaves out a device which was blocked" do
      publish(other_machine, as: other)
      self.accept_devices([other_user_id])

      devices.of(other_user_id).first.trust = :blocked

      expect(devices.recipients([other_user_id])).to be == []
    end
  end
end
