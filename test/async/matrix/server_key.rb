# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "base64"

require "async/matrix/server_key"

describe Async::Matrix::ServerKey do
  # The key the `synapse/` rig signs with, which is checked in so that the suite can sign as the homeserver it is testing.
  RIG = File.expand_path("../../../synapse/signing.key", __dir__)

  let(:key) {subject.load(RIG)}

  with ".parse" do
    it "reads the algorithm, the key ID and the seed" do
      parsed = subject.parse("ed25519 a_pxTp SnDmunk28k36o2ibXNWobfWLBguwZDy3xFsNprjwl+c")

      expect(parsed.key_id).to be == "a_pxTp"
      expect(parsed.algorithm).to be == "ed25519"
    end

    # The seed is written as unpadded base64, which is two characters short of a multiple of four.
    it "reads a seed whose padding was left off" do
      expect(subject.parse("ed25519 a_pxTp SnDmunk28k36o2ibXNWobfWLBguwZDy3xFsNprjwl+c").public_key).not.to be_nil
    end

    it "refuses an algorithm it cannot sign with" do
      expect do
        subject.parse("ed448 a_pxTp SnDmunk28k36o2ibXNWobfWLBguwZDy3xFsNprjwl+c")
      end.to raise_exception(Async::Matrix::InvalidKeyError)
    end

    it "refuses a line which is missing the seed" do
      expect do
        subject.parse("ed25519 a_pxTp")
      end.to raise_exception(Async::Matrix::InvalidKeyError)
    end

    it "refuses a seed which is the wrong size" do
      expect do
        subject.parse("ed25519 a_pxTp #{Base64.strict_encode64("short")}")
      end.to raise_exception(Async::Matrix::InvalidKeyError)
    end
  end

  with ".load" do
    it "reads the key the rig signs with" do
      expect(key.key_id).to be == "a_pxTp"
    end
  end

  with "#id" do
    it "names the key by its algorithm and ID" do
      expect(key.id).to be == "ed25519:a_pxTp"
    end
  end

  with "#public_key" do
    # What the homeserver publishes at `/_matrix/key/v2/server`, so the two must agree.
    it "derives the public half the homeserver publishes" do
      expect(key.public_key).to be == "a+PXPE5uXMXX7/7Zw+iy6AEPpyA+xE403oK7fInDy8M"
    end

    it "writes the key without padding" do
      expect(key.public_key).not.to be(:end_with?, "=")
    end
  end

  with "#sign" do
    it "signs an object, and verifies its own signature" do
      expect(key.verify({a: 1}, key.sign({a: 1}))).to be == true
    end

    # The signature is over the canonical form, so the order the object was written in cannot matter.
    it "signs the same whatever order the keys were given in" do
      expect(key.sign({a: 1, b: 2})).to be == key.sign({b: 2, a: 1})
    end

    # `signatures` is added after signing, so signing over it would be signing over itself.
    it "signs the object without its own signatures" do
      expect(key.sign({a: 1, signatures: {"localhost" => {}}})).to be == key.sign({a: 1})
    end

    it "writes the signature without padding" do
      expect(key.sign({a: 1})).not.to be(:end_with?, "=")
    end
  end

  with "#verify" do
    it "rejects a signature over another object" do
      expect(key.verify({a: 2}, key.sign({a: 1}))).to be == false
    end

    it "rejects something which is not a signature" do
      expect(key.verify({a: 1}, "not a signature")).to be == false
    end
  end
end
