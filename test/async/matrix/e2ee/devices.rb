# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/devices"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Devices do
  include_context Async::Matrix::E2EEContext

  let(:devices) {subject.new(client)}

  def published(display_name)
    {
      algorithms: ["m.megolm.v1.aes-sha2"],
      keys: {"curve25519:BOBPHONE": "aaa", "ed25519:BOBPHONE": "bbb"},
      unsigned: {device_display_name: display_name},
    }
  end

  with "#query" do
    it "asks the homeserver about the users it was given" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))

      queried = devices.query(["@bob:localhost"])

      expect(homeserver.queries).to be == [["@bob:localhost"]]
      expect(queried["@bob:localhost"].keys).to be == ["BOBPHONE"]
    end

    it "builds a device from what the server published" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))

      device = devices.of("@bob:localhost").first

      expect(device).to be_a(Async::Matrix::E2EE::Device)
      expect(device.user_id).to be == "@bob:localhost"
      expect(device.curve25519).to be == "aaa"
      expect(device.display_name).to be == "phone"
    end

    it "notes a user with no devices, so they are not asked about again" do
      devices.query(["@bob:localhost"])

      expect(devices).not.to be(:stale?, "@bob:localhost")
      expect(devices.of("@bob:localhost")).to be == []
    end
  end

  with "#for" do
    # A user nothing is known about has to be queried, which is the same as having been invalidated.
    it "queries a user it has never heard of" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))

      expect(devices).to be(:stale?, "@bob:localhost")

      devices.for(["@bob:localhost"])

      expect(homeserver.queries.size).to be == 1
    end

    it "does not query a user it already knows about" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))

      devices.for(["@bob:localhost"])
      devices.for(["@bob:localhost"])

      expect(homeserver.queries.size).to be == 1
    end

    it "queries only the users which are stale" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))
      devices.for(["@bob:localhost"])

      devices.for(["@bob:localhost", "@carol:localhost"])

      expect(homeserver.queries).to be == [["@bob:localhost"], ["@carol:localhost"]]
    end

    it "answers every user it was asked about, known or not" do
      expect(devices.for(["@bob:localhost"]).keys).to be == ["@bob:localhost"]
    end
  end

  with "#invalidate" do
    # Sync reports that a user's devices changed, never what they changed to, so the only answer is to ask again.
    it "makes a changed user stale, and queries them again" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))
      devices.for(["@bob:localhost"])

      devices.invalidate(changed: ["@bob:localhost"])

      expect(devices).to be(:stale?, "@bob:localhost")

      devices.for(["@bob:localhost"])

      expect(homeserver.queries.size).to be == 2
    end

    it "reads the devices again, so a renamed device is renamed here too" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))
      devices.for(["@bob:localhost"])

      homeserver.device("@bob:localhost", "BOBPHONE", published("laptop"))
      devices.invalidate(changed: ["@bob:localhost"])

      expect(devices.of("@bob:localhost").first.display_name).to be == "laptop"
    end

    it "forgets a user who is gone" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))
      devices.for(["@bob:localhost"])

      devices.invalidate(left: ["@bob:localhost"])

      expect(devices.devices).not.to be(:key?, "@bob:localhost")
    end
  end

  with "#receive" do
    it "notes everything a batch said about device lists" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))
      devices.for(["@bob:localhost", "@carol:localhost"])

      devices.receive(Async::Matrix::Offline::Batch.new(changed: ["@bob:localhost"], left: ["@carol:localhost"]))

      expect(devices).to be(:stale?, "@bob:localhost")
      expect(devices.devices).not.to be(:key?, "@carol:localhost")
    end
  end

  with "#recipients" do
    it "answers every device of every user it was given" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))
      homeserver.device("@bob:localhost", "BOBLAPTOP", published("laptop"))

      expect(devices.recipients(["@bob:localhost"]).map(&:device_id).sort).to be == ["BOBLAPTOP", "BOBPHONE"]
    end

    # A device does not send a room key to itself, because it already has the session.
    it "leaves out a device of our own" do
      homeserver.device("@alice:localhost", "ALICE", published("ours"))
      homeserver.device("@alice:localhost", "ALICEWEB", published("other"))

      expect(devices.recipients(["@alice:localhost"], except: "ALICE").map(&:device_id)).to be == ["ALICEWEB"]
    end

    it "leaves out a device which was blocked" do
      homeserver.device("@bob:localhost", "BOBPHONE", published("phone"))
      devices.of("@bob:localhost").first.trust = :blocked

      expect(devices.recipients(["@bob:localhost"])).to be == []
    end
  end
end
