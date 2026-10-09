# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "encrypted_message"
require_relative "errors"
require_relative "signing"

module Protocol
  module Matrix
    # The three key documents a device publishes through `POST /keys/upload`,
    # built and signed to the spec.
    #
    #   device_keys     who this device is: its identity keys, signed by itself.
    #                   Other devices verify everything we sign against the
    #                   ed25519 key in here.
    #   one_time_keys   consumable curve25519 keys. Another device CLAIMS one to
    #                   open an Olm session with us, and the server deletes it.
    #                   Run out and nobody can reach us: they cannot establish a
    #                   session, so they cannot send us a room key, so every
    #                   message in an encrypted room stays ciphertext.
    #   fallback_keys   one key per algorithm, answering claims after the
    #                   one-time keys are exhausted. NOT deleted when used,
    #                   which is the whole point — it is the backstop against
    #                   the failure above.
    #
    # Each takes raw key strings and an injected signer, so this builds and
    # signs documents without holding a key or knowing where one came from.
    module Keys
      # The algorithm name under which one-time and fallback keys are published.
      # "signed_" because the key object carries its own signature, which is
      # what lets a claimer verify it came from the device it names.
      SIGNED_CURVE25519 = "signed_curve25519"

      CURVE25519 = "curve25519"
      ED25519 = "ed25519"

      # What we tell other devices we can do. The same two algorithms
      # EncryptedMessage knows how to read, because claiming one we cannot
      # decrypt would have peers encrypt into a void.
      ALGORITHMS = EncryptedMessage::ALGORITHMS

      Error = Errors::KeysError

      # The signed device identity document.
      #
      # @parameter curve25519 [String] the device's identity key.
      # @parameter ed25519 [String] the device's fingerprint key.
      # @parameter signer [Object] answers `sign(String) -> base64`.
      # @returns [Hash] a DeviceKeys object, signed by this device.
      def self.device_keys(user_id:, device_id:, curve25519:, ed25519:, signer:, algorithms: ALGORITHMS)
        Signing.sign(
          {
            "algorithms" => algorithms,
            "device_id"  => device_id,
            "keys"       => {
              "#{CURVE25519}:#{device_id}" => curve25519,
              "#{ED25519}:#{device_id}"    => ed25519,
            },
            "user_id"    => user_id,
          },
          signer:  signer,
          user_id: user_id,
          key_id:  Signing.key_id(device_id),
        )
      end

      # Sign a batch of one-time keys for upload.
      #
      # @parameter keys [Hash] key_id => base64 curve25519 key, as the account
      #   reports its unpublished keys.
      # @returns [Hash] "signed_curve25519:<key_id>" => {"key" =>, "signatures" =>}
      #
      # EACH KEY IS SIGNED SEPARATELY, and that is not incidental: a claimer
      # receives one key object on its own, with no device-keys document
      # alongside it, so the signature on the key object is the only thing
      # tying it to our device.
      def self.one_time_keys(keys, user_id:, device_id:, signer:)
        keys.to_h do |key_id, key|
          [
            "#{SIGNED_CURVE25519}:#{key_id}",
            signed_key({"key" => key}, user_id: user_id, device_id: device_id, signer: signer),
          ]
        end
      end

      # A fallback key, in the same shape plus the marker that distinguishes it.
      #
      # "When uploading a signed key, an additional `fallback: true` key should
      # be included to denote that the key is a fallback key." It is part of the
      # SIGNED object, so a server cannot silently reclassify a one-time key as
      # a fallback (or the reverse) without breaking the signature.
      def self.fallback_keys(keys, user_id:, device_id:, signer:)
        keys.to_h do |key_id, key|
          [
            "#{SIGNED_CURVE25519}:#{key_id}",
            signed_key(
              {"fallback" => true, "key" => key},
              user_id:   user_id,
              device_id: device_id,
              signer:    signer,
            ),
          ]
        end
      end

      def self.signed_key(object, user_id:, device_id:, signer:)
        Signing.sign(
          object,
          signer:  signer,
          user_id: user_id,
          key_id:  Signing.key_id(device_id),
        )
      end

      # ── Reading other devices' keys ─────────────────────────────────────────

      # Pull one algorithm's key out of a DeviceKeys object.
      #
      # The key names are "<algorithm>:<device_id>", and the device_id must be
      # taken from the document rather than assumed, because a response from
      # /keys/query carries many devices at once.
      def self.key_for(device_keys, algorithm)
        device_id = device_keys["device_id"]

        if device_id.nil?
          nil
        else
          (device_keys["keys"] || {})["#{algorithm}:#{device_id}"]
        end
      end

      def self.identity_key(device_keys) = key_for(device_keys, CURVE25519)
      def self.fingerprint(device_keys) = key_for(device_keys, ED25519)

      # Is this DeviceKeys object correctly self-signed, and does it describe the
      # device it claims to?
      #
      # BOTH HALVES MATTER. A valid signature over a document whose user_id or
      # device_id disagrees with where we found it is a document for a DIFFERENT
      # device, replayed — so the spec has us "confirm that the `user_id` and
      # `device_id` match those of the top-level map entry".
      def self.valid_device_keys?(device_keys, user_id:, device_id:, verifier:)
        key = fingerprint(device_keys)

        if key.nil? || device_keys["user_id"] != user_id || device_keys["device_id"] != device_id
          false
        else
          Signing.verify(
            device_keys,
            key:      key,
            verifier: verifier,
            user_id:  user_id,
            key_id:   Signing.key_id(device_id),
          )
        end
      rescue Signing::MissingSignatureError
        false
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::Keys" do
    def signer(signature = "SIG")
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
      verifier.define_singleton_method(:verify_signature) { |_key, _message, _signature| result }
      verifier
    end

    def device_keys(**overrides)
      Protocol::Matrix::Keys.device_keys(
        **{
          user_id: "@alice:example.com",
          device_id: "JLAFKJWSCS",
          curve25519: "3C5BFWi2Y8MaVvjM8M22DBmh24PmgR0nPvJOIArzgyI",
          ed25519: "lEuiRJBit0IG6nUf5pUzWTUEsRVVe/HJkoKuEww9ULI",
          signer: signer,
        }.merge(overrides),
      )
    end

    # ── device_keys ───────────────────────────────────────────────────────────

    # Every field the DeviceKeys schema requires.
    it "builds the document the schema requires" do
      keys = device_keys

      keys["user_id"].should == "@alice:example.com"
      keys["device_id"].should == "JLAFKJWSCS"
      keys["algorithms"].should == ["m.olm.v1.curve25519-aes-sha2", "m.megolm.v1.aes-sha2"]
      keys["keys"].should == {
        "curve25519:JLAFKJWSCS" => "3C5BFWi2Y8MaVvjM8M22DBmh24PmgR0nPvJOIArzgyI",
        "ed25519:JLAFKJWSCS" => "lEuiRJBit0IG6nUf5pUzWTUEsRVVe/HJkoKuEww9ULI",
      }
      keys["signatures"].should == {"@alice:example.com" => {"ed25519:JLAFKJWSCS" => "SIG"}}
    end

    # The key names are "<algorithm>:<device_id>", so a different device id
    # renames them -- they are not fixed strings.
    it "names the keys after the device" do
      device_keys(device_id: "OTHERDEV")["keys"].keys.sort
        .should == ["curve25519:OTHERDEV", "ed25519:OTHERDEV"]
    end

    # We advertise exactly what EncryptedMessage can read: claiming an algorithm
    # we cannot decrypt would have peers encrypt into a void.
    it "advertises only algorithms we can actually read" do
      Protocol::Matrix::Keys::ALGORITHMS.should == Protocol::Matrix::EncryptedMessage::ALGORITHMS
    end

    it "accepts an explicit algorithm list" do
      device_keys(algorithms: ["m.megolm.v1.aes-sha2"])["algorithms"]
        .should == ["m.megolm.v1.aes-sha2"]
    end

    it "signs the canonical form of the document" do
      sign = signer
      device_keys(signer: sign)

      sign.signed.length.should == 1
      sign.signed.first.should ==
        '{"algorithms":["m.olm.v1.curve25519-aes-sha2","m.megolm.v1.aes-sha2"],' \
        '"device_id":"JLAFKJWSCS",' \
        '"keys":{"curve25519:JLAFKJWSCS":"3C5BFWi2Y8MaVvjM8M22DBmh24PmgR0nPvJOIArzgyI",' \
        '"ed25519:JLAFKJWSCS":"lEuiRJBit0IG6nUf5pUzWTUEsRVVe/HJkoKuEww9ULI"},' \
        '"user_id":"@alice:example.com"}'
    end

    # ── one_time_keys ─────────────────────────────────────────────────────────

    it "publishes one-time keys under signed_curve25519" do
      keys = Protocol::Matrix::Keys.one_time_keys(
        {"AAAAHg" => "zKbLg+NrIjpnagy+pIY6uPL4ZwEG2v+8F9lmgsnlZzs"},
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        signer: signer,
      )

      keys.keys.should == ["signed_curve25519:AAAAHg"]
      keys["signed_curve25519:AAAAHg"].should == {
        "key" => "zKbLg+NrIjpnagy+pIY6uPL4ZwEG2v+8F9lmgsnlZzs",
        "signatures" => {"@alice:example.com" => {"ed25519:JLAFKJWSCS" => "SIG"}},
      }
    end

    # A claimer receives ONE key object alone, with no device-keys document
    # beside it, so the signature on each key is the only thing tying it to us.
    it "signs each key separately" do
      sign = signer
      Protocol::Matrix::Keys.one_time_keys(
        {"one" => "KEY1", "two" => "KEY2"},
        user_id: "@alice:example.com",
        device_id: "DEV",
        signer: sign,
      )

      sign.signed.should == ['{"key":"KEY1"}', '{"key":"KEY2"}']
    end

    it "publishes nothing for an empty batch" do
      Protocol::Matrix::Keys.one_time_keys({}, user_id: "@a:b", device_id: "D", signer: signer)
        .should == {}
    end

    # ── fallback_keys ─────────────────────────────────────────────────────────

    # The marker is inside the SIGNED object, so a server cannot reclassify a
    # one-time key as a fallback (or the reverse) without breaking the signature.
    it "marks a fallback key, inside the signature" do
      sign = signer
      keys = Protocol::Matrix::Keys.fallback_keys(
        {"AAAAGj" => "zKbLg+NrIjpnagy+pIY6uPL4ZwEG2v+8F9lmgsnlZzs"},
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        signer: sign,
      )

      keys["signed_curve25519:AAAAGj"]["fallback"].should == true
      sign.signed.first.should ==
        '{"fallback":true,"key":"zKbLg+NrIjpnagy+pIY6uPL4ZwEG2v+8F9lmgsnlZzs"}'
    end

    # ── Reading another device's keys ─────────────────────────────────────────

    it "pulls the identity and fingerprint keys out of a document" do
      keys = device_keys

      Protocol::Matrix::Keys.identity_key(keys)
        .should == "3C5BFWi2Y8MaVvjM8M22DBmh24PmgR0nPvJOIArzgyI"
      Protocol::Matrix::Keys.fingerprint(keys)
        .should == "lEuiRJBit0IG6nUf5pUzWTUEsRVVe/HJkoKuEww9ULI"
    end

    # The device id comes from the document, because a /keys/query response
    # carries many devices at once.
    it "reads the keys of whichever device the document describes" do
      Protocol::Matrix::Keys.identity_key(device_keys(device_id: "OTHERDEV", curve25519: "THEIRS"))
        .should == "THEIRS"
    end

    it "answers nil for a document with no device id" do
      Protocol::Matrix::Keys.identity_key({"keys" => {"curve25519:D" => "K"}}).should.be.nil
    end

    it "accepts a correctly self-signed document" do
      Protocol::Matrix::Keys.valid_device_keys?(
        device_keys,
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        verifier: verifier,
      ).should == true
    end

    it "rejects a document whose signature does not verify" do
      Protocol::Matrix::Keys.valid_device_keys?(
        device_keys,
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        verifier: verifier(false),
      ).should == false
    end

    # "Confirm that the user_id and device_id match those of the top-level map
    # entry": a valid signature over a document describing a DIFFERENT device is
    # that other device's document, replayed.
    it "rejects a document that describes a different device" do
      Protocol::Matrix::Keys.valid_device_keys?(
        device_keys(device_id: "SOMEONEELSE"),
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        verifier: verifier,
      ).should == false
    end

    it "rejects a document that claims a different user" do
      Protocol::Matrix::Keys.valid_device_keys?(
        device_keys(user_id: "@mallory:example.com"),
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        verifier: verifier,
      ).should == false
    end

    it "rejects a document with no fingerprint key to verify against" do
      keys = device_keys
      keys["keys"].delete("ed25519:JLAFKJWSCS")

      Protocol::Matrix::Keys.valid_device_keys?(
        keys,
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        verifier: verifier,
      ).should == false
    end

    it "rejects an unsigned document rather than raising" do
      keys = device_keys
      keys.delete("signatures")

      Protocol::Matrix::Keys.valid_device_keys?(
        keys,
        user_id: "@alice:example.com",
        device_id: "JLAFKJWSCS",
        verifier: verifier,
      ).should == false
    end
  end
