# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "openssl"

require_relative "errors"

module Protocol
  module Matrix
    # Secure Secret Storage and Sharing -- "4S" -- the account-data vault that
    # holds secrets like the megolm backup key, unlocked by the user's recovery
    # key or passphrase.
    #
    # `m.secret_storage.v1.aes-hmac-sha2`, implemented on OpenSSL alone:
    # HKDF-SHA256, AES-256-CTR, HMAC-SHA256 and PBKDF2-HMAC-SHA512 are all
    # stdlib, so this adds no dependency and holds no key material. Nothing here
    # is novel cryptography -- it is the same construction every Matrix client
    # implements, and the point of having it is that the recovery key is the
    # only way into history that predates a device.
    module SecretStorage
      ALGORITHM = "m.secret_storage.v1.aes-hmac-sha2"
      PASSPHRASE_ALGORITHM = "m.pbkdf2"

      # "a salt of 32 bytes of 0, and the empty string as the info" -- fixed by
      # the spec throughout 4S. The per-secret `info` is the secret's NAME,
      # which is what stops one secret's ciphertext being replayed as another.
      ZERO_SALT = ("\x00" * 32).b

      # The key check encrypts "a message consisting of 32 bytes of 0".
      ZERO_MESSAGE = ("\x00" * 32).b

      # A recovery key is the raw key wrapped in a version prefix and a parity
      # byte, so a mistyped one fails loudly instead of decrypting to garbage.
      # https://spec.matrix.org/latest/appendices/#cryptographic-key-representation
      RECOVERY_KEY_PREFIX = [0x8B, 0x01].freeze
      KEY_LENGTH = 32
      BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

      DEFAULT_PASSPHRASE_BITS = 256

      Error = Errors::SecretStorageError
      MacError = Errors::SecretStorageMacError
      UnusableKeyError = Errors::UnusableKeyError

      # ── Getting to the storage key ──────────────────────────────────────────

      # The 32-byte storage key from whatever the user typed.
      #
      # Tries the recovery-key encoding first and falls back to treating the
      # input as a passphrase, which is only possible when the account's key
      # entry records the PBKDF2 parameters. Then VERIFIES it before returning,
      # so a typo reports itself here rather than as a wall of undecryptable
      # sessions later.
      def self.storage_key(input, key_info)
        (decode_recovery_key(input) || passphrase_key(input, key_info)).tap do |key|
          unless valid_key?(key, key_info)
            raise UnusableKeyError, "that key does not match this account's secret storage"
          end
        end
      end

      def self.passphrase_key(input, key_info)
        passphrase = key_info["passphrase"]

        if passphrase.nil?
          raise UnusableKeyError,
            "not a valid recovery key, and this account has no passphrase configured"
        end

        derive_from_passphrase(
          input,
          salt:       passphrase["salt"],
          iterations: passphrase["iterations"],
          bits:       passphrase["bits"] || DEFAULT_PASSPHRASE_BITS,
        )
      end

      # PBKDF2 "with SHA-512 as the hash", per the m.pbkdf2 algorithm.
      def self.derive_from_passphrase(passphrase, salt:, iterations:, bits: DEFAULT_PASSPHRASE_BITS)
        OpenSSL::PKCS5.pbkdf2_hmac(
          passphrase.to_s,
          salt.to_s,
          iterations.to_i,
          bits / 8,
          "SHA512",
        )
      end

      # ── Key representation ──────────────────────────────────────────────────

      # The 32-byte key from a displayed recovery key, or nil when the input is
      # not one -- a bad prefix, a bad length, or a parity byte that disagrees.
      # Nil rather than an exception, because "this is a passphrase instead" is
      # an ordinary answer.
      def self.decode_recovery_key(input)
        bytes = base58_decode(input.to_s.gsub(/\s+/, ""))

        if bytes.nil? || bytes.length != RECOVERY_KEY_PREFIX.length + KEY_LENGTH + 1
          nil
        elsif bytes[0, RECOVERY_KEY_PREFIX.length] != RECOVERY_KEY_PREFIX
          nil
        elsif bytes[0..-2].reduce(0) { |parity, byte| parity ^ byte } != bytes[-1]
          nil
        else
          bytes[RECOVERY_KEY_PREFIX.length, KEY_LENGTH].pack("C*")
        end
      end

      # A 32-byte key as the string a user is shown: prefix, parity byte,
      # base58, "a space is added after every 4th character".
      def self.encode_recovery_key(storage_key)
        bytes = RECOVERY_KEY_PREFIX + storage_key.bytes
        bytes << bytes.reduce(0) { |parity, byte| parity ^ byte }

        base58_encode(bytes).scan(/.{1,4}/).join(" ")
      end

      # ── Secrets ─────────────────────────────────────────────────────────────

      # HKDF-SHA256 to the two subkeys a secret is protected with: "The first 32
      # bytes are used as the AES key, and the next 32 bytes are used as the MAC
      # key."
      def self.subkeys(storage_key, info)
        okm = OpenSSL::KDF.hkdf(
          storage_key,
          salt:   ZERO_SALT,
          info:   info.to_s,
          length: 64,
          hash:   "SHA256",
        )

        [okm[0, 32], okm[32, 32]]
      end

      # Decrypt one account-data secret.
      #
      # @parameter name [String] the secret's name, which is the HKDF info.
      # @raises [MacError] unless the MAC verifies -- a wrong key must fail here
      #   rather than produce plausible rubbish.
      def self.decrypt_secret(storage_key, name:, ciphertext:, iv:, mac:)
        aes_key, mac_key = subkeys(storage_key, name)
        raw = decode64(ciphertext.to_s)

        unless mac_equal?(OpenSSL::HMAC.digest("SHA256", mac_key, raw), mac)
          raise MacError, "secret #{name} failed its MAC -- wrong recovery key?"
        end

        cipher = OpenSSL::Cipher.new("aes-256-ctr")
        cipher.decrypt
        cipher.key = aes_key
        cipher.iv = decode64(iv.to_s)
        cipher.update(raw) + cipher.final
      end

      # Does +storage_key+ open this key entry?
      #
      # The entry records the MAC of 32 zero bytes encrypted under an EMPTY info
      # string, so reproducing it proves the key without touching a real secret.
      # The `iv` and `mac` properties are optional: "If they are not present,
      # clients must assume that the key is valid", which is why an entry
      # without them answers true.
      def self.valid_key?(storage_key, key_info)
        if storage_key.nil?
          false
        elsif key_info.nil? || key_info["mac"].nil? || key_info["iv"].nil?
          true
        else
          aes_key, mac_key = subkeys(storage_key, "")

          cipher = OpenSSL::Cipher.new("aes-256-ctr")
          cipher.encrypt
          cipher.key = aes_key
          cipher.iv = decode64(key_info["iv"])
          ciphertext = cipher.update(ZERO_MESSAGE) + cipher.final

          mac_equal?(OpenSSL::HMAC.digest("SHA256", mac_key, ciphertext), key_info["mac"])
        end
      end

      # Compare a raw digest against a base64 MAC.
      #
      # DECODED, then compared in constant time. Padding is inconsistent between
      # implementations, so comparing the encoded strings would reject valid
      # MACs; and this gates a secret, so the comparison must not leak where it
      # diverged.
      def self.mac_equal?(digest, encoded)
        expected = decode64(encoded.to_s)

        if expected.empty?
          false
        else
          OpenSSL.secure_compare(digest[0, expected.bytesize].to_s, expected)
        end
      end

      # ── base64 ──────────────────────────────────────────────────────────────
      #
      # pack/unpack rather than the `base64` gem, which is a BUNDLED gem from
      # Ruby 3.4 and so has to be declared as a dependency to be required. The
      # protocol layer carries no dependencies, and these two lines are the
      # whole reason it would have needed one.

      # Matrix encodes these UNPADDED, so the padding is restored before
      # decoding -- "m0" is strict and rejects a short final group. Invalid
      # base64 decodes to empty rather than raising: it arrives from the
      # network, so it is bad input, not a bug.
      def self.decode64(string)
        text = string.to_s
        text += "=" * ((4 - (text.length % 4)) % 4)
        text.unpack1("m0").to_s
      rescue ArgumentError
        ""
      end

      def self.encode64(bytes) = [bytes].pack("m0")

      def self.encode64_unpadded(bytes) = encode64(bytes).delete("=")

      # ── base58 ──────────────────────────────────────────────────────────────
      # The Bitcoin alphabet, as the spec specifies.

      # An array of byte values, or nil when the input contains a character
      # outside the alphabet.
      def self.base58_decode(string)
        if string.empty?
          nil
        else
          number = 0
          outside = false

          string.each_char do |char|
            index = BASE58_ALPHABET.index(char)

            if index.nil?
              outside = true
              break
            end

            number = (number * 58) + index
          end

          if outside
            nil
          else
            leading_zeroes(string) + digits(number)
          end
        end
      end

      def self.base58_encode(bytes)
        number = bytes.reduce(0) { |total, byte| (total << 8) | byte }
        out = +""

        while number.positive?
          number, remainder = number.divmod(58)
          out.prepend(BASE58_ALPHABET[remainder])
        end

        bytes.each { |byte| byte.zero? ? out.prepend("1") : break }
        out
      end

      def self.digits(number)
        [].tap do |bytes|
          while number.positive?
            bytes.unshift(number & 0xFF)
            number >>= 8
          end
        end
      end

      # A leading "1" is a leading zero byte, which the arithmetic above cannot
      # represent.
      def self.leading_zeroes(string)
        [].tap do |zeroes|
          string.each_char { |char| char == "1" ? zeroes << 0 : break }
        end
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::SecretStorage" do
    S = Protocol::Matrix::SecretStorage

    def storage_key = ("k" * 32).b

    # Encrypt a secret by following the spec's steps, so the specs below are a
    # genuine round trip rather than assertions about constants.
    def encrypt_secret(key, name, plaintext, iv: ("i" * 16).b)
      aes_key, mac_key = S.subkeys(key, name)

      cipher = OpenSSL::Cipher.new("aes-256-ctr")
      cipher.encrypt
      cipher.key = aes_key
      cipher.iv = iv
      ciphertext = cipher.update(plaintext) + cipher.final

      {
        "ciphertext" => S.encode64(ciphertext),
        "iv" => S.encode64(iv),
        "mac" => S.encode64(OpenSSL::HMAC.digest("SHA256", mac_key, ciphertext)),
      }
    end

    # The key-check data: "the MAC of the result of encrypting 32 bytes of 0".
    def key_info_for(key, iv: ("v" * 16).b)
      aes_key, mac_key = S.subkeys(key, "")

      cipher = OpenSSL::Cipher.new("aes-256-ctr")
      cipher.encrypt
      cipher.key = aes_key
      cipher.iv = iv
      ciphertext = cipher.update(("\x00" * 32).b) + cipher.final

      {
        "algorithm" => S::ALGORITHM,
        "iv" => S.encode64(iv),
        "mac" => S.encode64(OpenSSL::HMAC.digest("SHA256", mac_key, ciphertext)),
      }
    end

    # ── Key representation ────────────────────────────────────────────────────

    it "round-trips a recovery key" do
      encoded = S.encode_recovery_key(storage_key)

      S.decode_recovery_key(encoded).should == storage_key
    end

    # "A space is added after every 4th character."
    it "groups the displayed key in fours" do
      groups = S.encode_recovery_key(storage_key).split(" ")

      groups[0..-2].map(&:length).uniq.should == [4]
      (1..4).cover?(groups.last.length).should == true
    end

    it "disregards whitespace when reading a key back" do
      encoded = S.encode_recovery_key(storage_key)

      S.decode_recovery_key(encoded.delete(" ")).should == storage_key
      S.decode_recovery_key("  #{encoded}\n").should == storage_key
    end

    # The parity byte is the point: a mistyped key must fail loudly rather than
    # decrypt to garbage.
    it "rejects a key whose parity byte disagrees" do
      bytes = S::RECOVERY_KEY_PREFIX + storage_key.bytes
      bytes << (bytes.reduce(0) { |parity, byte| parity ^ byte } ^ 0xFF)

      S.decode_recovery_key(S.base58_encode(bytes)).should.be.nil
    end

    it "rejects a key with the wrong prefix" do
      bytes = [0x00, 0x01] + storage_key.bytes
      bytes << bytes.reduce(0) { |parity, byte| parity ^ byte }

      S.decode_recovery_key(S.base58_encode(bytes)).should.be.nil
    end

    it "rejects a key of the wrong length" do
      bytes = S::RECOVERY_KEY_PREFIX + ("k" * 16).bytes
      bytes << bytes.reduce(0) { |parity, byte| parity ^ byte }

      S.decode_recovery_key(S.base58_encode(bytes)).should.be.nil
    end

    # Nil rather than raising: "this is a passphrase instead" is an ordinary
    # answer, not an error.
    it "answers nil for something that is not a recovery key at all" do
      S.decode_recovery_key("hunter2").should.be.nil
      S.decode_recovery_key("not base58 ~!@").should.be.nil
      S.decode_recovery_key("").should.be.nil
    end

    it "uses the bitcoin alphabet, which excludes 0, O, I and l" do
      %w[0 O I l].each { |char| S::BASE58_ALPHABET.include?(char).should == false }
    end

    # ── Passphrases ───────────────────────────────────────────────────────────

    # "PBKDF2 with SHA-512 as the hash"
    it "derives a key from a passphrase with PBKDF2-HMAC-SHA512" do
      derived = S.derive_from_passphrase("hunter2", salt: "salty", iterations: 1000)

      derived.bytesize.should == 32
      derived.should == OpenSSL::PKCS5.pbkdf2_hmac("hunter2", "salty", 1000, 32, "SHA512")
    end

    it "honours the bits parameter, defaulting to 256" do
      S.derive_from_passphrase("p", salt: "s", iterations: 10).bytesize.should == 32
      S.derive_from_passphrase("p", salt: "s", iterations: 10, bits: 512).bytesize.should == 64
    end

    # ── Secrets ───────────────────────────────────────────────────────────────

    it "decrypts a secret encrypted to the spec" do
      encrypted = encrypt_secret(storage_key, "m.megolm_backup.v1", "the backup key")

      S.decrypt_secret(
        storage_key,
        name: "m.megolm_backup.v1",
        ciphertext: encrypted["ciphertext"],
        iv: encrypted["iv"],
        mac: encrypted["mac"],
      ).should == "the backup key"
    end

    # The secret's NAME is the HKDF info, which is what stops one secret's
    # ciphertext being replayed as a different secret.
    it "refuses a secret decrypted under the wrong name" do
      encrypted = encrypt_secret(storage_key, "m.megolm_backup.v1", "the backup key")

      lambda {
        S.decrypt_secret(
          storage_key,
          name: "m.cross_signing.master",
          ciphertext: encrypted["ciphertext"],
          iv: encrypted["iv"],
          mac: encrypted["mac"],
        )
      }.should.raise(Protocol::Matrix::SecretStorage::MacError)
    end

    # A wrong key must fail here rather than produce plausible rubbish.
    it "refuses a secret under the wrong key" do
      encrypted = encrypt_secret(storage_key, "secret", "value")

      lambda {
        S.decrypt_secret(
          ("x" * 32).b,
          name: "secret",
          ciphertext: encrypted["ciphertext"],
          iv: encrypted["iv"],
          mac: encrypted["mac"],
        )
      }.should.raise(Protocol::Matrix::SecretStorage::MacError)
    end

    it "refuses tampered ciphertext" do
      encrypted = encrypt_secret(storage_key, "secret", "value")

      lambda {
        S.decrypt_secret(
          storage_key,
          name: "secret",
          ciphertext: S.encode64("tampered"),
          iv: encrypted["iv"],
          mac: encrypted["mac"],
        )
      }.should.raise(Protocol::Matrix::SecretStorage::MacError)
    end

    it "splits HKDF output into an AES key and a MAC key" do
      aes_key, mac_key = S.subkeys(storage_key, "name")

      aes_key.bytesize.should == 32
      mac_key.bytesize.should == 32
      aes_key.should.not == mac_key
    end

    # ── Verifying a key ───────────────────────────────────────────────────────

    it "accepts the key the entry was built from" do
      S.valid_key?(storage_key, key_info_for(storage_key)).should == true
    end

    it "rejects a key the entry was not built from" do
      S.valid_key?(("x" * 32).b, key_info_for(storage_key)).should == false
    end

    # "these properties are optional. If they are not present, clients must
    # assume that the key is valid."
    it "assumes a key is valid when the entry records no check" do
      S.valid_key?(storage_key, {"algorithm" => S::ALGORITHM}).should == true
      S.valid_key?(storage_key, {}).should == true
      S.valid_key?(storage_key, nil).should == true
    end

    it "rejects a nil key outright" do
      S.valid_key?(nil, key_info_for(storage_key)).should == false
    end

    # ── storage_key ───────────────────────────────────────────────────────────

    it "accepts a recovery key and verifies it" do
      S.storage_key(S.encode_recovery_key(storage_key), key_info_for(storage_key))
        .should == storage_key
    end

    it "falls back to treating the input as a passphrase" do
      derived = S.derive_from_passphrase("hunter2", salt: "salty", iterations: 100)
      info = key_info_for(derived).merge(
        "passphrase" => {"algorithm" => "m.pbkdf2", "salt" => "salty", "iterations" => 100},
      )

      S.storage_key("hunter2", info).should == derived
    end

    # A typo must report itself here, not as a wall of undecryptable sessions.
    it "refuses a recovery key that does not match the account" do
      lambda {
        S.storage_key(S.encode_recovery_key(("x" * 32).b), key_info_for(storage_key))
      }.should.raise(Protocol::Matrix::SecretStorage::UnusableKeyError)
    end

    it "says plainly when a passphrase cannot be used" do
      lambda {
        S.storage_key("hunter2", key_info_for(storage_key))
      }.should.raise(Protocol::Matrix::SecretStorage::UnusableKeyError)
    end

    # ── MAC comparison ────────────────────────────────────────────────────────

    # Padding is inconsistent between implementations, so comparing the encoded
    # strings would reject valid MACs.
    it "compares MACs by their decoded bytes, padded or not" do
      digest = OpenSSL::HMAC.digest("SHA256", "key", "message")

      S.mac_equal?(digest, S.encode64(digest)).should == true
      S.mac_equal?(digest, S.encode64(digest).delete("=")).should == true
      S.mac_equal?(digest, S.encode64("different")).should == false
      S.mac_equal?(digest, "").should == false
      S.mac_equal?(digest, nil).should == false
    end
  end
