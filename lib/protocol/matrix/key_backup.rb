# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"
require "openssl"

require_relative "error"
require_relative "secret_storage"

module Protocol
  module Matrix
    # Server-side key backup: `m.megolm_backup.v1.curve25519-aes-sha2`.
    #
    # THIS IS THE ONLY WAY TO READ HISTORY THAT PREDATES A DEVICE. A device is
    # only ever sent `m.room_key` for messages encrypted while it existed and
    # was known to the sender; everything older stays ciphertext forever. Key
    # backup is the account-wide escrow that fixes it: every client uploads its
    # room keys encrypted to a public key whose private half lives in 4S behind
    # the user's recovery key.
    #
    #   recovery key ─▶ 4S storage key ─▶ m.megolm_backup.v1 (the backup PRIVATE key)
    #                                                │
    #   GET /room_keys/keys ─▶ per-session blobs ────┘ decrypt (X25519 + AES-CBC)
    #                                                │
    #                                                ▼
    #                            an exported session key, importable as inbound
    #
    # Implemented on OpenSSL rather than through vodozemac, whose equivalent
    # sits behind an `insecure-pk-encryption` feature flag. That label is about
    # the SCHEME -- it does not authenticate the ciphertext's sender -- which is
    # a property of the Matrix format we must interoperate with either way.
    module KeyBackup
      ALGORITHM = "m.megolm_backup.v1.curve25519-aes-sha2"

      # "a salt of 32 bytes of 0, and with the empty string as the info"
      ZERO_SALT = SecretStorage::ZERO_SALT

      # "The first 8 bytes of the resulting MAC"
      MAC_LENGTH = 8

      # 80 bytes: "The first 32 bytes are used as the AES key, the next 32 bytes
      # are used as the MAC key, and the last 16 bytes are used as the AES
      # initialization vector."
      DERIVED_LENGTH = 80

      class Error < Protocol::Matrix::Error; end
      class MacError < Error; end

      # Decrypt one backed-up session blob to its BackedUpSessionData.
      #
      # @parameter private_key [String] the raw 32-byte backup private key, out
      #   of 4S.
      # @parameter session_data [Hash] the blob's `ephemeral`, `ciphertext`, `mac`.
      # @returns [Hash | Nil] the session data, or nil when the blob cannot be
      #   read at all (missing or empty fields).
      # @raises [MacError] when the MAC does not verify.
      #
      # NIL RATHER THAN RAISING for an unreadable blob: a mature backup
      # routinely contains keys written by clients with slightly different
      # habits, and one bad entry must not abandon the thousands after it.
      def self.decrypt_session(private_key, session_data)
        if session_data.nil?
          nil
        else
          ephemeral = SecretStorage.decode64(session_data["ephemeral"].to_s)
          ciphertext = SecretStorage.decode64(session_data["ciphertext"].to_s)

          if ephemeral.empty? || ciphertext.empty?
            nil
          else
            decrypt_blob(
              private_key,
              ephemeral,
              ciphertext,
              session_data["mac"],
            )
          end
        end
      end

      def self.decrypt_blob(private_key, ephemeral, ciphertext, mac)
        aes_key, mac_key, iv = subkeys(private_key, ephemeral)

        unless SecretStorage.mac_equal?(expected_mac(mac_key), mac)
          raise MacError, "backed-up session failed its MAC -- wrong backup key?"
        end

        cipher = OpenSSL::Cipher.new("aes-256-cbc")
        cipher.decrypt
        cipher.key = aes_key
        cipher.iv = iv

        parse(cipher.update(ciphertext) + cipher.final)
      rescue OpenSSL::OpenSSLError
        nil
      end

      # THE MAC IS OVER AN EMPTY STRING, and that is not a mistake here.
      #
      # The spec's step 5 says to "pass an empty string through HMAC-SHA-256
      # using the MAC key", with a warning attached: "Step 5 was intended to
      # pass the raw encrypted data, but due to a bug in libolm, all
      # implementations have since passed an empty string instead."
      #
      # So MACing the ciphertext -- the obvious reading, and what our previous
      # implementation did -- rejects every blob any real client ever wrote. The
      # consequence worth knowing is that this MAC proves only that we derived
      # the same MAC key, i.e. that the ECDH matched: it is a key check, not an
      # integrity check on the data. MSC4048 is the proposed fix.
      def self.expected_mac(mac_key)
        OpenSSL::HMAC.digest("SHA256", mac_key, "")[0, MAC_LENGTH]
      end

      # X25519 ECDH against the blob's ephemeral key, expanded to the three
      # subkeys the scheme uses.
      def self.subkeys(private_key, ephemeral)
        shared = ecdh(private_key, ephemeral)
        okm = OpenSSL::KDF.hkdf(
          shared,
          salt:   ZERO_SALT,
          info:   "",
          length: DERIVED_LENGTH,
          hash:   "SHA256",
        )

        [okm[0, 32], okm[32, 32], okm[64, 16]]
      end

      def self.ecdh(private_key, peer_public_key)
        OpenSSL::PKey.new_raw_private_key("X25519", private_key)
          .derive(OpenSSL::PKey.new_raw_public_key("X25519", peer_public_key))
      end

      # The public half of a backup private key, unpadded base64 -- what the
      # backup version's auth_data publishes.
      def self.public_key_for(private_key)
        SecretStorage.encode64_unpadded(
          OpenSSL::PKey.new_raw_private_key("X25519", private_key).raw_public_key,
        )
      end

      # Is this private key the one this backup version was encrypted to?
      #
      # Worth checking before walking thousands of blobs: the alternative is
      # every single one failing its MAC, which looks like a corrupt backup
      # rather than the wrong key.
      def self.key_matches?(private_key, auth_data)
        public_key = (auth_data || {})["public_key"]

        if public_key.nil?
          false
        else
          public_key.delete("=") == public_key_for(private_key)
        end
      end

      def self.parse(plaintext)
        JSON.parse(plaintext)
      rescue JSON::ParserError
        nil
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::KeyBackup" do
    B = Protocol::Matrix::KeyBackup

    def backup_keypair
      key = OpenSSL::PKey.generate_key("X25519")
      [key.raw_private_key, key.raw_public_key]
    end

    def session_payload
      {
        "algorithm" => "m.megolm.v1.aes-sha2",
        "forwarding_curve25519_key_chain" => [],
        "sender_key" => "RF3s+E7RkTQTGF2d8Deol0FkQvgII2aJDf3/Jp5mxVU",
        "sender_claimed_keys" => {"ed25519" => "aj40p+aw64yPIdsxoog8jhPu9i7l7NcFRecuOQblE3Y"},
        "session_key" => "AgAAAADxKHa9uFxcXzwYoNueL5Xqi69IkD4sni8Llf",
      }
    end

    # Back a session up by following the spec's own five steps, so these specs
    # are a real round trip. Step 5 is the one that matters: the MAC is over an
    # EMPTY STRING, which is what every real implementation does.
    def back_up(public_key, payload, mac_over: :empty)
      ephemeral = OpenSSL::PKey.generate_key("X25519")
      shared = ephemeral.derive(OpenSSL::PKey.new_raw_public_key("X25519", public_key))
      okm = OpenSSL::KDF.hkdf(shared, salt: B::ZERO_SALT, info: "", length: 80, hash: "SHA256")
      aes_key, mac_key, iv = okm[0, 32], okm[32, 32], okm[64, 16]

      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.encrypt
      cipher.key = aes_key
      cipher.iv = iv
      ciphertext = cipher.update(JSON.generate(payload)) + cipher.final

      mac_input = mac_over == :empty ? "" : ciphertext

      {
        "ephemeral" => Protocol::Matrix::SecretStorage.encode64(ephemeral.raw_public_key),
        "ciphertext" => Protocol::Matrix::SecretStorage.encode64(ciphertext),
        "mac" => Protocol::Matrix::SecretStorage.encode64(
          OpenSSL::HMAC.digest("SHA256", mac_key, mac_input)[0, B::MAC_LENGTH],
        ),
      }
    end

    # ── Decrypting a blob ─────────────────────────────────────────────────────

    it "decrypts a backed-up session" do
      private_key, public_key = backup_keypair

      B.decrypt_session(private_key, back_up(public_key, session_payload))
        .should == session_payload
    end

    # The field that carries the sending device's ed25519 key, which is how a
    # restored session can still be attributed to a device.
    it "recovers sender_claimed_keys with the session" do
      private_key, public_key = backup_keypair

      B.decrypt_session(private_key, back_up(public_key, session_payload))["sender_claimed_keys"]
        .should == {"ed25519" => "aj40p+aw64yPIdsxoog8jhPu9i7l7NcFRecuOQblE3Y"}
    end

    # THE REGRESSION THAT MATTERED. The spec says step 5 MACs an empty string,
    # with a warning that it "was intended to pass the raw encrypted data, but
    # due to a bug in libolm, all implementations have since passed an empty
    # string instead". MACing the ciphertext rejects every blob a real client
    # ever wrote.
    it "accepts the empty-string MAC every real client writes" do
      private_key, public_key = backup_keypair

      B.decrypt_session(private_key, back_up(public_key, session_payload, mac_over: :empty))
        .should.not.be.nil
    end

    it "rejects a blob MACed over the ciphertext, which nothing produces" do
      private_key, public_key = backup_keypair

      lambda {
        B.decrypt_session(private_key, back_up(public_key, session_payload, mac_over: :ciphertext))
      }.should.raise(Protocol::Matrix::KeyBackup::MacError)
    end

    it "refuses a blob backed up to a different key" do
      _private_key, public_key = backup_keypair
      other_private, = backup_keypair

      lambda {
        B.decrypt_session(other_private, back_up(public_key, session_payload))
      }.should.raise(Protocol::Matrix::KeyBackup::MacError)
    end

    # One unreadable entry must not abandon the thousands after it.
    it "answers nil for a blob it cannot read at all" do
      private_key, = backup_keypair

      B.decrypt_session(private_key, nil).should.be.nil
      B.decrypt_session(private_key, {}).should.be.nil
      B.decrypt_session(private_key, {"ephemeral" => "", "ciphertext" => ""}).should.be.nil
    end

    it "answers nil when the plaintext is not JSON" do
      private_key, public_key = backup_keypair
      blob = back_up(public_key, session_payload)
      # Same key, same MAC, but ciphertext that decrypts to rubbish.
      ephemeral = Protocol::Matrix::SecretStorage.decode64(blob["ephemeral"])
      aes_key, _mac_key, iv = B.subkeys(private_key, ephemeral)
      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.encrypt
      cipher.key = aes_key
      cipher.iv = iv
      blob["ciphertext"] = Protocol::Matrix::SecretStorage.encode64(cipher.update("not json") + cipher.final)

      B.decrypt_session(private_key, blob).should.be.nil
    end

    # ── Subkeys ───────────────────────────────────────────────────────────────

    # "The first 32 bytes are used as the AES key, the next 32 bytes are used as
    # the MAC key, and the last 16 bytes are used as the AES initialization
    # vector."
    it "derives 80 bytes as an aes key, a mac key and an iv" do
      private_key, = backup_keypair
      _other_private, other_public = backup_keypair
      aes_key, mac_key, iv = B.subkeys(private_key, other_public)

      aes_key.bytesize.should == 32
      mac_key.bytesize.should == 32
      iv.bytesize.should == 16
    end

    # Both sides of an ECDH reach the same secret, which is what makes the
    # scheme work at all.
    it "agrees with the sender's ECDH" do
      private_key, public_key = backup_keypair
      ephemeral_private, ephemeral_public = backup_keypair

      B.ecdh(private_key, ephemeral_public).should == B.ecdh(ephemeral_private, public_key)
    end

    # ── The backup version's public key ───────────────────────────────────────

    it "derives the public half a backup version publishes" do
      private_key, public_key = backup_keypair

      B.public_key_for(private_key).should == Protocol::Matrix::SecretStorage.encode64(public_key).delete("=")
    end

    it "emits the public key unpadded" do
      private_key, = backup_keypair

      B.public_key_for(private_key).include?("=").should == false
    end

    # Worth checking before walking thousands of blobs: the alternative is every
    # one failing its MAC, which looks like a corrupt backup rather than the
    # wrong key.
    it "recognises the key a backup version was made for" do
      private_key, = backup_keypair
      other_private, = backup_keypair
      auth_data = {"public_key" => B.public_key_for(private_key)}

      B.key_matches?(private_key, auth_data).should == true
      B.key_matches?(other_private, auth_data).should == false
    end

    it "tolerates padding in the published public key" do
      private_key, public_key = backup_keypair

      B.key_matches?(private_key, {"public_key" => Protocol::Matrix::SecretStorage.encode64(public_key)})
        .should == true
    end

    it "answers false for auth data with no public key" do
      private_key, = backup_keypair

      B.key_matches?(private_key, {}).should == false
      B.key_matches?(private_key, nil).should == false
    end
  end
