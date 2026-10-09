# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "canonical_json"
require_relative "errors"

module Protocol
  module Matrix
    # Signing JSON, per https://spec.matrix.org/latest/appendices/#signing-json
    #
    # The procedure, in full:
    #
    #   1. remove `signatures` and `unsigned`
    #   2. encode what is left as canonical JSON
    #   3. sign those bytes with ed25519
    #   4. encode the signature as UNPADDED base64
    #   5. store it under signatures[entity]["<algorithm>:<key_id>"]
    #
    # THE KEY MATERIAL IS INJECTED. `signer` is anything answering
    # `sign(String) -> base64`, and `verifier` anything answering
    # `verify_signature(key, message, signature) -> bool` — which is the shape
    # the native E2EE module already exposes. So this file implements the
    # procedure and holds no keys, which is what lets it sit in the protocol
    # layer and be tested without cryptography.
    module Signing
      ED25519 = "ed25519"

      # "{algorithm}:{key_id}" — for a device key the key_id is the device id.
      def self.key_id(name, algorithm: ED25519)
        "#{algorithm}:#{name}"
      end

      # Sign +object+ as +user_id+ with +key_id+.
      #
      # @returns [Hash] a copy of +object+ with the signature added. EXISTING
      #   SIGNATURES ARE PRESERVED: a device-keys object legitimately carries
      #   several (our device key, our self-signing key, another user's
      #   attestation), and replacing the map rather than merging into it would
      #   silently discard them.
      def self.sign(object, signer:, user_id:, key_id:)
        signature = sign_bytes(CanonicalJson.signable_bytes(object), signer: signer)
        existing = object["signatures"] || object[:signatures] || {}
        mine = existing[user_id] || {}

        object.merge(
          "signatures" => existing.merge(user_id => mine.merge(key_id => signature)),
        )
      end

      # Sign the given bytes, returning unpadded base64.
      #
      # PADDING IS STRIPPED HERE rather than assumed absent. The spec requires
      # unpadded base64, and whether a given primitive emits padding is its own
      # business; a stray "=" would make every signature we produce fail
      # verification everywhere, which is an expensive thing to discover
      # remotely.
      def self.sign_bytes(message, signer:)
        signer.sign(message).delete_suffix("==").delete_suffix("=")
      end

      # Is +object+ correctly signed by +user_id+ with +key_id+?
      #
      # @parameter key [String] the public ed25519 key to verify against.
      # @parameter verifier [Object] answers
      #   `verify_signature(key, message, signature) -> bool`.
      # @raises [Protocol::Matrix::Errors::MissingSignatureError] when there is no such signature to check
      #   — distinct from a signature that is present and wrong, because the two
      #   mean different things about the sender.
      def self.verify(object, key:, verifier:, user_id:, key_id:)
        signature = signature_for(object, user_id: user_id, key_id: key_id)

        if signature.nil?
          raise Protocol::Matrix::Errors::MissingSignatureError, "no #{key_id} signature from #{user_id}"
        end

        verifier.verify_signature(key, CanonicalJson.signable_bytes(object), signature)
      end

      # The signature +user_id+ made with +key_id+, or nil.
      def self.signature_for(object, user_id:, key_id:)
        signatures = object["signatures"] || object[:signatures] || {}
        (signatures[user_id] || {})[key_id]
      end

      def self.signed_by?(object, user_id:, key_id:)
        !signature_for(object, user_id: user_id, key_id: key_id).nil?
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::Signing" do
    # A signer that records what it was asked to sign, so a spec can assert on
    # the exact bytes the signature covers.
    def recording_signer(signature = "SIGNATURE")
      signer = Object.new
      signed = []
      signer.define_singleton_method(:signed) { signed }
      signer.define_singleton_method(:sign) do |message|
        signed << message
        signature
      end
      signer
    end

    def verifier(result = true)
      verifier = Object.new
      calls = []
      verifier.define_singleton_method(:calls) { calls }
      verifier.define_singleton_method(:verify_signature) do |key, message, signature|
        calls << [key, message, signature]
        result
      end
      verifier
    end

    it "builds a key identifier" do
      Protocol::Matrix::Signing.key_id("JLAFKJWSCS").should == "ed25519:JLAFKJWSCS"
      Protocol::Matrix::Signing.key_id("1", algorithm: "ed25519").should == "ed25519:1"
    end

    it "stores the signature under entity and key identifier" do
      signed = Protocol::Matrix::Signing.sign(
        {"a" => 1},
        signer: recording_signer,
        user_id: "@alice:example.com",
        key_id: "ed25519:DEV",
      )

      signed["signatures"].should == {"@alice:example.com" => {"ed25519:DEV" => "SIGNATURE"}}
    end

    # The signature covers canonical JSON of the object MINUS signatures and
    # unsigned.
    it "signs the canonical form, excluding signatures and unsigned" do
      signer = recording_signer
      Protocol::Matrix::Signing.sign(
        {"b" => 2, "a" => 1, "unsigned" => {"age" => 1}},
        signer: signer,
        user_id: "@alice:example.com",
        key_id: "ed25519:DEV",
      )

      signer.signed.should == ['{"a":1,"b":2}']
    end

    # A device-keys object legitimately carries several signatures; replacing the
    # map rather than merging into it would discard them.
    it "preserves signatures already present" do
      object = {
        "a" => 1,
        "signatures" => {
          "@bob:example.com" => {"ed25519:OTHER" => "theirs"},
          "@alice:example.com" => {"ed25519:SSK" => "self-signing"},
        },
      }
      signed = Protocol::Matrix::Signing.sign(
        object,
        signer: recording_signer,
        user_id: "@alice:example.com",
        key_id: "ed25519:DEV",
      )

      signed["signatures"]["@bob:example.com"].should == {"ed25519:OTHER" => "theirs"}
      signed["signatures"]["@alice:example.com"].should == {
        "ed25519:SSK" => "self-signing", "ed25519:DEV" => "SIGNATURE",
      }
    end

    it "returns a copy rather than mutating its argument" do
      object = {"a" => 1}
      Protocol::Matrix::Signing.sign(
        object,
        signer: recording_signer,
        user_id: "@alice:example.com",
        key_id: "ed25519:DEV",
      )

      object.key?("signatures").should == false
    end

    # The spec requires UNPADDED base64. Whether a primitive emits padding is its
    # own business; a stray "=" would fail verification everywhere.
    it "strips base64 padding from whatever the signer returns" do
      Protocol::Matrix::Signing.sign_bytes("msg", signer: recording_signer("abc=")).should == "abc"
      Protocol::Matrix::Signing.sign_bytes("msg", signer: recording_signer("abc==")).should == "abc"
      Protocol::Matrix::Signing.sign_bytes("msg", signer: recording_signer("abc")).should == "abc"
    end

    # ── Verifying ─────────────────────────────────────────────────────────────

    it "verifies against the same bytes it would have signed" do
      check = verifier
      object = {
        "b" => 2,
        "a" => 1,
        "signatures" => {"@alice:example.com" => {"ed25519:DEV" => "SIG"}},
      }

      Protocol::Matrix::Signing.verify(
        object,
        key: "PUBKEY",
        verifier: check,
        user_id: "@alice:example.com",
        key_id: "ed25519:DEV",
      ).should == true

      check.calls.should == [["PUBKEY", '{"a":1,"b":2}', "SIG"]]
    end

    it "reports a signature that does not verify" do
      Protocol::Matrix::Signing.verify(
        {"a" => 1, "signatures" => {"@alice:example.com" => {"ed25519:DEV" => "SIG"}}},
        key: "PUBKEY",
        verifier: verifier(false),
        user_id: "@alice:example.com",
        key_id: "ed25519:DEV",
      ).should == false
    end

    # "A signature that is absent" and "a signature that is wrong" say different
    # things about the sender, so they are not the same answer.
    it "distinguishes a missing signature from a bad one" do
      lambda {
        Protocol::Matrix::Signing.verify(
          {"a" => 1},
          key: "PUBKEY",
          verifier: verifier,
          user_id: "@alice:example.com",
          key_id: "ed25519:DEV",
        )
      }.should.raise(Protocol::Matrix::Errors::MissingSignatureError)
    end

    it "treats a signature from a different key as missing" do
      lambda {
        Protocol::Matrix::Signing.verify(
          {"signatures" => {"@alice:example.com" => {"ed25519:OTHER" => "SIG"}}},
          key: "PUBKEY",
          verifier: verifier,
          user_id: "@alice:example.com",
          key_id: "ed25519:DEV",
        )
      }.should.raise(Protocol::Matrix::Errors::MissingSignatureError)
    end

    it "finds a signature, or reports its absence" do
      object = {"signatures" => {"@alice:example.com" => {"ed25519:DEV" => "SIG"}}}

      Protocol::Matrix::Signing.signature_for(object, user_id: "@alice:example.com", key_id: "ed25519:DEV")
        .should == "SIG"
      Protocol::Matrix::Signing.signed_by?(object, user_id: "@alice:example.com", key_id: "ed25519:DEV")
        .should == true
      Protocol::Matrix::Signing.signed_by?(object, user_id: "@bob:example.com", key_id: "ed25519:DEV")
        .should == false
    end

    # A signature survives a round trip through canonical JSON regardless of the
    # order the object was built in -- which is the entire purpose of the
    # canonical encoding.
    it "signs two differently ordered objects identically" do
      first = recording_signer
      second = recording_signer

      Protocol::Matrix::Signing.sign({"a" => 1, "b" => 2}, signer: first, user_id: "@a:b", key_id: "ed25519:D")
      Protocol::Matrix::Signing.sign({"b" => 2, "a" => 1}, signer: second, user_id: "@a:b", key_id: "ed25519:D")

      first.signed.should == second.signed
    end
  end
