# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "digest"
require "json"

require "async/matrix/server_key"
require "async/matrix/signatures"

describe Async::Matrix::Signatures do
  # The seed the appendices sign every one of their test vectors with.
  let(:key) {Async::Matrix::ServerKey.parse("ed25519 1 YJDBA9Xnr2sVqXD9Vj7XVUnmFZcZrlw8Md7kMW+3XA1")}

  # Another key, for a signature which this one did not make.
  let(:other_key) {Async::Matrix::ServerKey.parse("ed25519 2 YW5vdGhlciBzZWVkIHdoaWNoIGlzIHRoaXJ0eSB0d28")}

  let(:keyring) {Async::Matrix::Signatures::Keyring.new.add("domain", key.id, key.public_key)}

  # The fields `compute_content_hash` drops, which are the ones no sender wrote.
  HASHED = [:age_ts, :unsigned, :signatures, :hashes, :outlier, :destinations].freeze

  # The hash of an event as it was sent, which the appendices' event vectors carry.
  #
  # @parameter event [Hash] the event to hash.
  # @returns [String] the hash, as unpadded base64.
  def content_hash(event)
    Async::Matrix::ServerKey.encode(Digest::SHA256.digest(Async::Matrix::E2EE::CanonicalJSON.dump(event.reject{|key, _| HASHED.include?(key)})))
  end

  # The appendices' "JSON Signing" vectors, which name the signature an object must come out with.
  with "the JSON signing vectors" do
    it "signs an empty object as the appendices do" do
      signed = subject.sign({}, key: key, as: "domain")

      expect(signed[:signatures]["domain"][key.id]).to be == "K8280/U9SSy9IVtjBuVeLr+HpOB4BQFWbg+UZaADMtTdGYI7Geitb76LTrr5QV/7Xg4ahLwYGYZzuHGZKM5ZAQ"
    end

    it "signs an object with values in it as the appendices do" do
      signed = subject.sign({one: 1, two: "Two"}, key: key, as: "domain")

      expect(signed[:signatures]["domain"][key.id]).to be == "KqmLSbO39/Bzb0QIYE82zqLwsA+PDzYIpIRA2sRQ4sL53+sN6/fpNSoqE7BP7vBZhG6kYdD13EIMJpvhJI+6Bw"
    end

    it "verifies what it signed" do
      expect(subject.verify?(subject.sign({one: 1, two: "Two"}, key: key, as: "domain"), entity: "domain", keyring: keyring)).to be == true
    end
  end

  # The appendices' "Event Signing" vectors, whose signature covers the redacted event and its hash.
  with "the event signing vectors" do
    let(:minimal) do
      {room_id: "!x:domain", sender: "@a:domain", origin: "domain", origin_server_ts: 1000000, signatures: {}, hashes: {}, type: "X", content: {}, prev_events: [], auth_events: [], depth: 3, unsigned: {age_ts: 1000000}}
    end

    let(:message) do
      {content: {body: "Here is the message content"}, event_id: "$0:domain", origin: "domain", origin_server_ts: 1000000, type: "m.room.message", room_id: "!r:domain", sender: "@u:domain", signatures: {}, unsigned: {age_ts: 1000000}}
    end

    it "hashes the minimal event as the appendices do" do
      expect(content_hash(minimal)).to be == "5jM4wQpv6lnBo7CLIghJuHdW+s2CMBJPUOGOC89ncos"
    end

    it "signs the minimal event as the appendices do" do
      redacted = {auth_events: [], content: {}, depth: 3, hashes: {sha256: content_hash(minimal)}, origin: "domain", origin_server_ts: 1000000, prev_events: [], room_id: "!x:domain", sender: "@a:domain", signatures: {}, type: "X"}

      expect(subject.sign(redacted, key: key, as: "domain")[:signatures]["domain"][key.id]).to be == "KxwGjPSDEtvnFgU00fwFz+l6d2pJM6XBIaMEn81SXPTRl16AqLAYqfIReFGZlHi5KLjAWbOoMszkwsQma+lYAg"
    end

    it "hashes an event with redactable content as the appendices do" do
      expect(content_hash(message)).to be == "onLKD1bGljeBWQhWZ1kaP9SorVmRQNdN5aM2JYU2n/g"
    end

    it "signs an event with redactable content as the appendices do" do
      redacted = {content: {}, event_id: "$0:domain", hashes: {sha256: content_hash(message)}, origin: "domain", origin_server_ts: 1000000, room_id: "!r:domain", sender: "@u:domain", signatures: {}, type: "m.room.message"}

      expect(subject.sign(redacted, key: key, as: "domain")[:signatures]["domain"][key.id]).to be == "Wm+VzmOUOz08Ds+0NTWb1d4CZrVsJSikkeRxh6aCcUwu6pNC78FunoD7KNWzqFn241eYHYMGCA5McEiVPdhzBA"
    end
  end

  with ".sign" do
    # The signature is added to what was there, so that an intermediate entity can add its own.
    it "keeps the signatures already made" do
      signed = subject.sign({a: 1}, key: key, as: "domain")
      both = subject.sign(signed, key: other_key, as: "other.org")

      expect(both[:signatures].keys.sort).to be == ["domain", "other.org"]
      expect(both[:signatures]["domain"][key.id]).to be == signed[:signatures]["domain"][key.id]
    end

    # One entity with two keys is what a rotation looks like while both are still published.
    it "keeps another signature by the same entity" do
      signed = subject.sign({a: 1}, key: key, as: "domain")

      expect(subject.sign(signed, key: other_key, as: "domain")[:signatures]["domain"].keys.sort).to be == ["ed25519:1", "ed25519:2"]
    end

    # The signature covers neither of them, so the server's own fields survive being signed over.
    it "keeps the unsigned fields" do
      expect(subject.sign({a: 1, unsigned: {age_ts: 10}}, key: key, as: "domain")[:unsigned]).to be == {age_ts: 10}
    end

    it "leaves the object it was given alone" do
      object = {a: 1}
      subject.sign(object, key: key, as: "domain")

      expect(object).to be == {a: 1}
    end

    it "reads an object whose keys are strings" do
      signed = subject.sign({"a" => 1, "signatures" => {}}, key: key, as: "domain")

      expect(signed["signatures"]["domain"][key.id]).not.to be_nil
    end
  end

  with ".verify!" do
    let(:signed) {subject.sign({a: 1}, key: key, as: "domain")}

    it "answers the key identifiers which verified" do
      expect(subject.verify!(signed, entity: "domain", keyring: keyring)).to be == [key.id]
    end

    # The first step: there must be an entry under the name of the entity.
    it "fails where the entity signed nothing" do
      error = nil

      begin
        subject.verify!(signed, entity: "nobody.org", keyring: keyring)
      rescue Async::Matrix::SignatureError => error
      end

      expect(error.reason).to be == :no_entity
      expect(error.entity).to be == "nobody.org"
    end

    # The second step: the identifiers whose algorithm we do not know are dropped.
    it "fails where no signature uses an algorithm it knows" do
      object = {a: 1, signatures: {"domain" => {"rot13:1" => "whatever"}}}

      expect{subject.verify!(object, entity: "domain", keyring: keyring)}.to raise_exception(Async::Matrix::SignatureError, message: be =~ /algorithm/)
    end

    # The third step: a key identifier we understand is no use without the key itself.
    it "fails where there is no verification key" do
      error = nil

      begin
        subject.verify!(signed, entity: "domain", keyring: Async::Matrix::Signatures::Keyring.new)
      rescue Async::Matrix::SignatureError => error
      end

      expect(error.reason).to be == :no_verification_key
    end

    # The fourth step: the signature bytes are decoded before anything is checked against them.
    it "fails where the signature is not base64" do
      object = {a: 1, signatures: {"domain" => {key.id => "not base64!"}}}
      error = nil

      begin
        subject.verify!(object, entity: "domain", keyring: keyring)
      rescue Async::Matrix::SignatureError => error
      end

      expect(error.reason).to be == :malformed_signature
      expect(error.key_id).to be == key.id
    end

    # The last step, which is the signature itself.
    it "fails where the object is not what was signed" do
      error = nil

      begin
        subject.verify!(signed.merge(a: 2), entity: "domain", keyring: keyring)
      rescue Async::Matrix::SignatureError => error
      end

      expect(error.reason).to be == :mismatch
    end

    # Every signature we hold a key for has to verify, not merely one of them.
    it "fails where one of the entity's signatures does not match" do
      two = subject.sign(subject.sign({a: 1}, key: key, as: "domain"), key: other_key, as: "domain")
      forged = two.merge(signatures: {"domain" => two[:signatures]["domain"].merge(other_key.id => key.sign({a: 2}))})
      both = keyring.add("domain", other_key.id, other_key.public_key)

      expect{subject.verify!(forged, entity: "domain", keyring: both)}.to raise_exception(Async::Matrix::SignatureError, message: be =~ /does not match/)
    end

    # A signature made with a key nobody has is passed over rather than failing the check.
    it "ignores a signature it has no key for, where another verifies" do
      two = subject.sign(subject.sign({a: 1}, key: key, as: "domain"), key: other_key, as: "domain")

      expect(subject.verify!(two, entity: "domain", keyring: keyring)).to be == [key.id]
    end

    it "verifies after the server added its own fields" do
      answered = signed.merge(unsigned: {age_ts: 10})

      expect(subject.verify?(answered, entity: "domain", keyring: keyring)).to be == true
    end
  end

  # The device keys `matrix-rust-sdk` checks in `signature_test`, signed by another implementation.
  with "a device another implementation signed" do
    let(:device) do
      JSON.parse(<<~JSON, symbolize_names: true)
        {
          "device_id": "GBEWHQOYGS",
          "algorithms": ["m.olm.v1.curve25519-aes-sha2", "m.megolm.v1.aes-sha2"],
          "keys": {
            "curve25519:GBEWHQOYGS": "F8QhZ0Z1rjtWrQOblMDgZtEX5x1UrG7sZ2Kk3xliNAU",
            "ed25519:GBEWHQOYGS": "n469gw7zm+KW+JsFIJKnFVvCKU14HwQyocggcCIQgZY"
          },
          "signatures": {
            "@example:localhost": {
              "ed25519:GBEWHQOYGS": "OlF2REsqjYdAfr04ONx8VS/5cB7KjrWYRlLF4eUm2foAiQL/RAfsjsa2JXZeoOHh6vEualZHbWlod49OewVqBg"
            }
          },
          "unsigned": {"device_display_name": "Weechat-Matrix-rs"},
          "user_id": "@example:localhost"
        }
      JSON
    end

    # The whole algorithm, over an object this library did not write: the user is the entity.
    it "verifies the signature over the device keys" do
      keyring = Async::Matrix::Signatures::Keyring.for_device(device)

      expect(subject.verify!(device, entity: "@example:localhost", keyring: keyring)).to be == ["ed25519:GBEWHQOYGS"]
    end

    # The curve25519 key is published beside the signing key, and signs nothing.
    it "checks the signature against the key which made it" do
      expect(Async::Matrix::Signatures::Keyring.for_device(device)["@example:localhost"].keys).to be == ["ed25519:GBEWHQOYGS"]
    end
  end
end
