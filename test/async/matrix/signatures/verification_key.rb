# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/server_key"
require "async/matrix/signatures/verification_key"

describe Async::Matrix::Signatures::VerificationKey do
  # The key the appendices sign their own vectors with.
  let(:signing_key) {Async::Matrix::ServerKey.parse("ed25519 1 YJDBA9Xnr2sVqXD9Vj7XVUnmFZcZrlw8Md7kMW+3XA1")}

  let(:key) {subject.parse("ed25519:1", signing_key.public_key)}

  with ".parse" do
    it "reads a key whose algorithm it knows" do
      expect(key.algorithm).to be == "ed25519"
      expect(key.encoded).to be == signing_key.public_key
    end

    # The second step of the check drops these rather than failing, so nothing is raised here.
    it "answers nothing for an algorithm it cannot check" do
      expect(subject.parse("curve25519:GBEWHQOYGS", "F8QhZ0Z1rjtWrQOblMDgZtEX5x1UrG7sZ2Kk3xliNAU")).to be_nil
      expect(subject.parse("rot13:1", "whatever")).to be_nil
    end

    it "refuses a key of the right algorithm which cannot be read" do
      expect{subject.parse("ed25519:1", "obviously not a key")}.to raise_exception(Async::Matrix::InvalidKeyError)
    end
  end

  with ".supported?" do
    it "knows the algorithm the specification defines" do
      expect(subject.supported?("ed25519:1")).to be == true
      expect(subject.supported?("ed25519:AAAAHQ")).to be == true
    end

    it "does not know the others" do
      ["curve25519:1", "rot13:1", "ed448:1", "", "ed25519"].each do |key_id|
        expect(subject.supported?(key_id)).to be == (key_id == "ed25519")
      end
    end
  end

  with ".algorithm_of" do
    # A signing key identifier is the algorithm and a key identifier, which may itself hold no colon.
    it "reads the algorithm from the identifier" do
      expect(subject.algorithm_of("ed25519:a_pxTp")).to be == "ed25519"
      expect(subject.algorithm_of(:"ed25519:1")).to be == "ed25519"
    end
  end

  with ".decode" do
    # The specification writes base64 without padding, and a decoder wants it back.
    it "reads unpadded base64" do
      expect(subject.decode("Zm9vYmFy")).to be == "foobar"
      expect(subject.decode("Zm9vYmE")).to be == "fooba"
      expect(subject.decode("Zg")).to be == "f"
      expect(subject.decode("")).to be == ""
    end

    it "refuses what is not base64" do
      expect{subject.decode("not base64!")}.to raise_exception(ArgumentError)
    end
  end

  with "#verify" do
    let(:signature) {Async::Matrix::Signatures::VerificationKey.decode(signing_key.sign({a: 1}))}

    let(:bytes) {Async::Matrix::E2EE::CanonicalJSON.for_signing({a: 1})}

    it "accepts a signature this key made" do
      expect(key.verify(bytes, signature)).to be == true
    end

    it "refuses a signature over something else" do
      expect(key.verify(Async::Matrix::E2EE::CanonicalJSON.for_signing({a: 2}), signature)).to be == false
    end

    it "refuses a signature another key made" do
      other = Async::Matrix::ServerKey.parse("ed25519 2 YW5vdGhlciBzZWVkIHdoaWNoIGlzIHRoaXJ0eSB0d28")

      expect(key.verify(bytes, Async::Matrix::Signatures::VerificationKey.decode(other.sign({a: 1})))).to be == false
    end

    it "refuses bytes which are not a signature at all" do
      expect(key.verify(bytes, "short")).to be == false
    end
  end
end
