# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/secrets"
require "async/matrix/events"

describe Async::Matrix::E2EE::Secrets do
  let(:secrets) {subject.new}

  let(:key_id) {"storage-key"}

  # The passphrase the account's storage was derived from, and the description which says how.
  let(:passphrase) {"correct horse"}

  let(:salt) {"salt"}

  let(:iterations) {1000}

  let(:key) {Async::Matrix::E2EE::SecretStorage::Key.from_passphrase(passphrase, salt: salt, iterations: iterations)}

  # What `m.secret_storage.key.<id>` holds for a key a passphrase derives.
  let(:storage) do
    key.description(
      name: "Default key",
      passphrase: {algorithm: Async::Matrix::E2EE::SecretStorage::PBKDF2, salt: salt, iterations: iterations},
    )
  end

  # The account's storage, described but not yet open.
  def described
    secrets.tap do
      secrets.describe(key_id, storage)
    end
  end

  # The account's storage, open under the key the passphrase derives.
  def opened
    described.tap do
      secrets.unlock(passphrase)
    end
  end

  with "#describe" do
    it "notes which key the account's storage is encrypted under" do
      expect(described.key_id).to be == key_id
    end

    # Describing it says only how to arrive at the key, so nothing is open yet.
    it "opens nothing by itself" do
      expect(described).not.to be(:open?)
    end
  end

  with "#unlock" do
    it "opens the storage with the passphrase it was derived from" do
      expect(described.unlock(passphrase)).to be == true
      expect(secrets).to be(:open?)
    end

    # The check in the description is what tells a wrong passphrase from a right one.
    it "refuses a passphrase which derives another key" do
      expect(described.unlock("battery staple")).to be == false
      expect(secrets).not.to be(:open?)
    end

    it "refuses where nothing has described a storage" do
      expect(secrets.unlock(passphrase)).to be == false
      expect(secrets).not.to be(:open?)
    end

    it "refuses where the storage was not derived from a passphrase" do
      secrets.describe(key_id, Async::Matrix::E2EE::SecretStorage::Key.generate.description)

      expect(secrets.unlock(passphrase)).to be == false
      expect(secrets).not.to be(:open?)
    end

    # The bits are part of the derivation, so a description which asks for fewer is honoured.
    it "opens a storage whose description asks for a key of its own length" do
      derived = Async::Matrix::E2EE::SecretStorage::Key.from_passphrase(passphrase, salt: salt, iterations: iterations, bits: 128)
      secrets.describe(key_id, derived.description(passphrase: {algorithm: Async::Matrix::E2EE::SecretStorage::PBKDF2, salt: salt, iterations: iterations, bits: 128}))

      expect(secrets.unlock(passphrase)).to be == true
    end
  end

  with "#opened" do
    it "opens the storage with the key itself, which is what a sibling device sends" do
      expect(described.opened(key)).to be == true
      expect(secrets).to be(:open?)
    end

    it "refuses a key the description was not written by" do
      expect(described.opened(Async::Matrix::E2EE::SecretStorage::Key.generate)).to be == false
      expect(secrets).not.to be(:open?)
    end

    # Both properties are optional, and where they are absent the key must be assumed valid.
    it "takes any key where the description carries no check" do
      secrets.describe(key_id, {algorithm: Async::Matrix::E2EE::SecretStorage::ALGORITHM})

      expect(secrets.opened(Async::Matrix::E2EE::SecretStorage::Key.generate)).to be == true
      expect(secrets).to be(:open?)
    end
  end

  with "#accept" do
    it "holds a secret however this device came by it" do
      secrets.accept("m.megolm_backup.v1", "the-backup-key")

      expect(secrets.held("m.megolm_backup.v1")).to be == "the-backup-key"
    end

    it "holds nothing where there was nothing to hold" do
      secrets.accept("m.megolm_backup.v1", nil)

      expect(secrets.held("m.megolm_backup.v1")).to be_nil
    end
  end

  with "#held" do
    it "answers nothing for a secret this device does not hold" do
      expect(secrets.held("m.megolm_backup.v1")).to be_nil
    end
  end

  with "#store" do
    it "answers the account data to set, sealed under the storage key" do
      written = opened.store("m.megolm_backup.v1" => "the-backup-key")
      sealed = written["m.megolm_backup.v1"][:encrypted][key_id]

      expect(sealed.keys.sort).to be == [:ciphertext, :iv, :mac]
      expect(key.decrypt("m.megolm_backup.v1", sealed)).to be == "the-backup-key"
    end

    it "holds what it wrote, so it can be read without reading it back" do
      opened.store("m.megolm_backup.v1" => "the-backup-key")

      expect(secrets.held("m.megolm_backup.v1")).to be == "the-backup-key"
    end

    it "writes each secret it was given" do
      written = opened.store("m.megolm_backup.v1" => "backup", "m.cross_signing.master" => "master")

      expect(written.keys.sort).to be == ["m.cross_signing.master", "m.megolm_backup.v1"]
    end

    # Without a storage key there is nowhere to put it, so it is held for this session and no further.
    it "writes nothing where no storage is open" do
      written = secrets.store("m.megolm_backup.v1" => "the-backup-key")

      expect(written).to be == {}
      expect(secrets.held("m.megolm_backup.v1")).to be == "the-backup-key"
    end

    it "takes a name which was given as a symbol" do
      written = opened.store("m.megolm_backup.v1": "the-backup-key")

      expect(written.keys).to be == ["m.megolm_backup.v1"]
    end
  end

  with "#load" do
    # This is the whole point of storage: a new device opens it and reads what another device left.
    it "reads a secret which was sealed under this storage" do
      sealed = {key_id.to_sym => key.encrypt("m.megolm_backup.v1", "the-backup-key")}
      described.sealed("m.megolm_backup.v1", sealed)
      secrets.unlock(passphrase)

      expect(secrets.load("m.megolm_backup.v1")).to be == "the-backup-key"
    end

    # Opening the storage reads everything which was sealed under it, so nothing has to ask twice.
    it "holds what it read, so opening the storage is what reads it" do
      sealed = {key_id.to_sym => key.encrypt("m.megolm_backup.v1", "the-backup-key")}
      described.sealed("m.megolm_backup.v1", sealed)
      secrets.unlock(passphrase)

      expect(secrets.held("m.megolm_backup.v1")).to be == "the-backup-key"
    end

    it "answers nothing for a secret nothing sealed" do
      expect(opened.load("m.megolm_backup.v1")).to be_nil
    end

    # A secret sealed under a key this device does not have is somebody else's to read.
    it "answers nothing for a secret sealed under another key" do
      sealed = {"another-key": key.encrypt("m.megolm_backup.v1", "the-backup-key")}
      described.sealed("m.megolm_backup.v1", sealed)
      secrets.unlock(passphrase)

      expect(secrets.load("m.megolm_backup.v1")).to be_nil
    end

    it "answers what this device holds while the storage is shut" do
      described.sealed("m.megolm_backup.v1", {key_id.to_sym => key.encrypt("m.megolm_backup.v1", "sealed")})
      secrets.accept("m.megolm_backup.v1", "held")

      expect(secrets.load("m.megolm_backup.v1")).to be == "held"
    end
  end

  with "#asking" do
    it "remembers what was asked for, so an answer can be matched to the question" do
      secrets.asking("request-1", "m.megolm_backup.v1")

      expect(secrets.requested("request-1")).to be == "m.megolm_backup.v1"
    end

    it "remembers nothing about a request it did not make" do
      expect(secrets.requested("request-1")).to be_nil
    end
  end

  with "#asked?" do
    # A secret arriving unbidden is somebody trying their luck, so it is never taken.
    it "refuses an answer to something nothing asked for" do
      expect(secrets.asked?("request-1")).to be == false
    end

    it "believes an answer which arrived over Olm" do
      secrets.asking("request-1", "m.megolm_backup.v1")

      over = Async::Matrix::Events::Decrypted.new({type: "m.secret.send"}, {})

      expect(secrets.asked?("request-1", over: over)).to be == true
    end

    # Nothing was said about how it arrived, so the caller has already judged that.
    it "believes an answer whose channel the caller judged itself" do
      secrets.asking("request-1", "m.megolm_backup.v1")

      expect(secrets.asked?("request-1")).to be == true
    end

    # In the clear is not a channel which says who sent it, whatever the event claims.
    it "refuses an answer which arrived unencrypted" do
      secrets.asking("request-1", "m.megolm_backup.v1")

      over = Async::Matrix::Events::Envelope.new({type: "m.secret.send"}, {})

      expect(secrets.asked?("request-1", over: over)).to be == false
    end
  end

  with "#cancel" do
    it "forgets a request which was answered or withdrawn" do
      secrets.asking("request-1", "m.megolm_backup.v1")
      secrets.cancel("request-1")

      expect(secrets.requested("request-1")).to be_nil
      expect(secrets.asked?("request-1")).to be == false
    end
  end

  with "#from_passphrase" do
    it "derives the key a description describes" do
      derived = secrets.from_passphrase(passphrase, salt: salt, iterations: iterations)

      expect(derived.bytes).to be == key.bytes
    end
  end
end
