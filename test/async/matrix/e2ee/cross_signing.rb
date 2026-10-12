# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/cross_signing"

describe Async::Matrix::E2EE::CrossSigning do
  let(:user_id) {"@alice:localhost"}

  let(:identity) {subject.generate(user_id)}

  let(:other_identity) {subject.generate("@bob:localhost")}

  # The device keys a device publishes, which are what the self signing key signs.
  let(:device_keys) do
    {
      user_id: user_id,
      device_id: "DEVICE",
      algorithms: ["m.olm.v1.curve25519-aes-sha2", "m.megolm.v1.aes-sha2"],
      keys: {"curve25519:DEVICE" => "curve25519-key", "ed25519:DEVICE" => "ed25519-key"},
    }
  end

  with ".generate" do
    it "makes all three keys" do
      expect(identity.master_key).not.to be_nil
      expect(identity.self_signing_key).not.to be_nil
      expect(identity.user_signing_key).not.to be_nil
    end

    it "makes three different keys" do
      expect([identity.master_key, identity.self_signing_key, identity.user_signing_key].uniq.size).to be == 3
    end

    it "belongs to the user it was made for" do
      expect(identity.user_id).to be == user_id
    end

    it "holds the private half of each, which is what goes to secret storage" do
      expect(identity.private_master).not.to be_nil
      expect(identity.private_self_signing).not.to be_nil
      expect(identity.private_user_signing).not.to be_nil
    end
  end

  with "#[]" do
    it "answers each of the three" do
      expect(identity[:master].public_key).to be == identity.master_key
      expect(identity[:self_signing].public_key).to be == identity.self_signing_key
      expect(identity[:user_signing].public_key).to be == identity.user_signing_key
    end

    it "answers nothing for a key this device does not hold" do
      expect(subject.new(user_id)[:master]).to be_nil
    end
  end

  with "#[]=" do
    # This is how a second device comes by the identity: the private halves arrive from storage.
    it "takes on a key which arrived from somewhere else" do
      second = subject.new(user_id)
      second[:master] = Async::Matrix::E2EE::CrossSigning::Key.from_base64(identity.private_master)

      expect(second.master_key).to be == identity.master_key
    end
  end

  with "#master" do
    it "publishes the key under its own name, as the specification asks" do
      expect(identity.master).to be == {
        user_id: user_id,
        usage: ["master"],
        keys: {"ed25519:#{identity.master_key}" => identity.master_key},
      }
    end

    # The master key is the identity, so nothing else signs it.
    it "carries no signature" do
      expect(identity.master.keys).not.to be(:include?, :signatures)
    end

    it "refuses to publish a key this device does not hold" do
      expect{subject.new(user_id).master}.to raise_exception(KeyError)
    end
  end

  with "#self_signing" do
    it "says what the key is for" do
      expect(identity.self_signing[:usage]).to be == ["self_signing"]
      expect(identity.self_signing[:keys]).to be == {"ed25519:#{identity.self_signing_key}" => identity.self_signing_key}
    end

    # Verifying a person once covers every device they have, and this is the link which makes that true.
    it "is signed by the master key" do
      published = identity.self_signing
      signature = published[:signatures][user_id]["ed25519:#{identity.master_key}"]

      expect(signature).not.to be_nil
      expect(identity[:master].verify(published, signature)).to be == true
    end

    it "refuses to publish without the master key to sign with" do
      alone = subject.new(user_id, self_signing: Async::Matrix::E2EE::CrossSigning::Key.generate)

      expect{alone.self_signing}.to raise_exception(KeyError)
    end
  end

  with "#user_signing" do
    it "says what the key is for" do
      expect(identity.user_signing[:usage]).to be == ["user_signing"]
    end

    it "is signed by the master key" do
      published = identity.user_signing
      signature = published[:signatures][user_id]["ed25519:#{identity.master_key}"]

      expect(identity[:master].verify(published, signature)).to be == true
    end
  end

  with "#sign_device" do
    # A device which carries this signature is one its owner says is theirs, which is what cross signed means.
    it "signs the device keys with the self signing key" do
      signatures = identity.sign_device(device_keys)
      signature = signatures[user_id]["DEVICE"]["ed25519:#{identity.self_signing_key}"]

      expect(signature).not.to be_nil
      expect(identity[:self_signing].verify(device_keys, signature)).to be == true
    end

    it "answers nothing without the key to sign with" do
      expect(subject.new(user_id).sign_device(device_keys)).to be_nil
    end
  end

  with "#sign_master" do
    # This is what verifying another person is: our user signing key over their master key.
    it "signs their master key with the user signing key" do
      theirs = other_identity.master
      signatures = identity.sign_master(other_identity.user_id, theirs)
      signature = signatures[other_identity.user_id][other_identity.master_key]["ed25519:#{identity.user_signing_key}"]

      expect(signature).not.to be_nil
      expect(identity[:user_signing].verify(theirs, signature)).to be == true
    end

    it "answers nothing without the key to sign with" do
      expect(subject.new(user_id).sign_master(other_identity.user_id, other_identity.master)).to be_nil
    end
  end

  with "USAGE" do
    it "names what each of the three keys is for" do
      expect(subject::USAGE).to be == {master: "master", self_signing: "self_signing", user_signing: "user_signing"}
    end
  end
end

describe Async::Matrix::E2EE::CrossSigning::Key do
  let(:key) {subject.generate}

  let(:other) {subject.generate}

  with ".generate" do
    it "makes a different key each time" do
      expect(other.public_key).not.to be == key.public_key
    end
  end

  with ".from_base64" do
    it "is the same key as the private half it was given" do
      expect(subject.from_base64(key.private_key).public_key).to be == key.public_key
    end

    # The specification carries base64 unpadded, and the binding refuses padding rather than ignoring it.
    it "takes a key whose padding a client left on" do
      expect(subject.from_base64("#{key.private_key}==").public_key).to be == key.public_key
    end
  end

  with "#sign" do
    it "writes a signature this key verifies" do
      expect(key.verify({a: 1}, key.sign({a: 1}))).to be == true
    end

    # The canonical form is what is signed, so the order the fields were given in cannot matter.
    it "writes a signature which verifies whatever order the fields arrived in" do
      expect(key.verify({b: 2, a: 1}, key.sign({a: 1, b: 2}))).to be == true
    end

    # A signature cannot cover itself, and `unsigned` is whatever the server chose to add.
    it "writes a signature which verifies once the server has added its own fields" do
      object = {a: 1}
      signature = key.sign(object)
      answered = object.merge(signatures: {"@alice:localhost" => {}}, unsigned: {age: 10})

      expect(key.verify(answered, signature)).to be == true
    end
  end

  with "#verify" do
    it "refuses a signature another key made" do
      expect(key.verify({a: 1}, other.sign({a: 1}))).to be == false
    end

    it "refuses a signature over something else" do
      expect(key.verify({a: 2}, key.sign({a: 1}))).to be == false
    end

    # A signature which is not a signature at all is a wrong answer rather than a crash.
    it "refuses something which is not a signature" do
      expect(key.verify({a: 1}, "not-a-signature")).to be == false
      expect(key.verify({a: 1}, "")).to be == false
    end
  end

  with ".verify" do
    it "checks a signature against a key which arrived as a name" do
      expect(subject.verify(key.public_key, {a: 1}, key.sign({a: 1}))).to be == true
      expect(subject.verify(other.public_key, {a: 1}, key.sign({a: 1}))).to be == false
    end

    it "refuses a key which is not a key" do
      expect(subject.verify("not-a-key", {a: 1}, key.sign({a: 1}))).to be == false
    end
  end

  with ".unpadded" do
    it "takes padding off" do
      expect(subject.unpadded("aGVsbG8=")).to be == "aGVsbG8"
    end
  end
end
