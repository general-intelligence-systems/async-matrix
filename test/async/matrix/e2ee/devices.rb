# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/devices"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Devices do
  include Async::Matrix::E2EEContext

  let(:devices) {machine.devices}

  with "#query" do
    it "asks the homeserver about the users it was given" do
      other_machine.publish!

      queried = devices.query([other_user_id])

      expect(queried[other_user_id].keys).to be == [other_device_id]
    end

    it "builds a device from what the other user published" do
      other_machine.publish!

      device = devices.of(other_user_id).first

      expect(device).to be_a(Async::Matrix::E2EE::Device)
      expect(device.user_id).to be == other_user_id
      expect(device.curve25519).to be == other_crypto.identity_keys[:curve25519]
    end

    # A user is only encrypted to once they have published keys, and until then the homeserver answers with nothing.
    it "notes a user with no devices, so they are not asked about again" do
      devices.query([other_user_id])

      expect(devices).not.to be(:stale?, other_user_id)
      expect(devices.of(other_user_id)).to be == []
    end

    it "answers every device the other user has published" do
      other_machine.publish!
      second = self.account(other_username)
      Async::Matrix::E2EE::Machine.new(second).publish!

      expect(devices.of(other_user_id).map(&:device_id).sort).to be == [other_device_id, second.get_token_owner.device_id].sort
    end
  end

  with "#for" do
    # A user nothing is known about has to be queried, which is the same as having been invalidated.
    it "queries a user it has never heard of" do
      other_machine.publish!

      expect(devices).to be(:stale?, other_user_id)
      expect(devices.for([other_user_id])[other_user_id]).not.to be(:empty?)
    end

    # A query for every message would be a request for every message, which is what the device list in sync is for.
    it "does not query the homeserver again for a user it knows about" do
      other_machine.publish!
      devices.for([other_user_id])

      other.devices.update_device(other_device_id, display_name: "Renamed")

      expect(devices.for([other_user_id])[other_user_id][other_device_id].display_name).to be_nil
    end

    it "answers every user it was asked about, known or not" do
      expect(devices.for([other_user_id]).keys).to be == [other_user_id]
    end
  end

  with "#invalidate" do
    # Sync reports that a user's devices changed, never what they changed to, so the only answer is to ask again.
    it "reads the devices again, so a renamed device is renamed here too" do
      other_machine.publish!
      devices.for([other_user_id])

      other.devices.update_device(other_device_id, display_name: "Renamed")
      devices.invalidate(changed: [other_user_id])

      expect(devices).to be(:stale?, other_user_id)
      expect(devices.of(other_user_id).first.display_name).to be == "Renamed"
    end

    it "forgets a user who is gone" do
      other_machine.publish!
      devices.for([other_user_id])

      devices.invalidate(left: [other_user_id])

      expect(devices.devices).not.to be(:key?, other_user_id)
    end
  end

  with "#receive" do
    # The homeserver reports a device list change for the users whose rooms we share, which is how a client knows to ask again.
    it "notes the change the homeserver reported when the other user added a device" do
      shared_room
      other_machine.publish!
      devices.for([other_user_id])

      # The cursor has to predate the change, or there is nothing for the server to report it against:
      since = current_sync
      self.account(other_username)

      sync = sync_after(since){|batch| batch.changed_devices.include?(other_user_id)}

      expect(sync).not.to be_nil

      machine.receive(sync)

      expect(devices).to be(:stale?, other_user_id)
    end
  end

  with "#recipients" do
    it "answers every device of every user it was given" do
      other_machine.publish!

      expect(devices.recipients([other_user_id]).map(&:device_id)).to be == [other_device_id]
    end

    # A device does not send a room key to itself, because it already has the session.
    it "leaves out a device of our own" do
      machine.publish!

      expect(devices.recipients([user_id], except: machine.device_id)).to be == []
      expect(devices.recipients([user_id]).map(&:device_id)).to be == [machine.device_id]
    end

    it "leaves out a device which was blocked" do
      other_machine.publish!
      devices.of(other_user_id).first.trust = :blocked

      expect(devices.recipients([other_user_id])).to be == []
    end
  end
end
