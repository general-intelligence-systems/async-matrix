# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "base64"
require "openssl"
require "securerandom"

require_relative "../key_representation"

module Async
  module Matrix
    module E2EE
      # Secrets the server keeps but cannot read.
      module SecretStorage
        # They are encrypted under a key the server never sees, and the cross signing keys and the backup key live here, so that a new device can reach them.

        # The only algorithm the specification defines.
        ALGORITHM = "m.secret_storage.v1.aes-hmac-sha2"

        # The only way of deriving one from a passphrase.
        PBKDF2 = "m.pbkdf2"

        # What a key is, and what a passphrase derives to.
        BYTES = 32

        # The salt the derivation uses, which is fixed at nothing.
        ZERO_SALT = ("\x00" * 32).b

        # What the check value encrypts, which is nothing in particular.
        ZERO_MESSAGE = ("\x00" * 32).b

        # The key secret storage is encrypted under.
        class Key
          # It never leaves the device: what goes to the server is what it encrypted, and a description which only says how to arrive at it again.

          # @returns [Key] a key of random bytes, which the user keeps.
          def self.generate
            self.new(SecureRandom.bytes(BYTES))
          end

          # @parameter bytes [String] the raw key.
          # @returns [Key] that key.
          def self.from_bytes(bytes)
            self.new(bytes.b)
          end

          # The key a passphrase arrives at, which is the same every time for the same description.
          #
          # @parameter passphrase [String] what the user typed.
          # @parameter salt [String] the salt from the key's description.
          # @parameter iterations [Integer] how many rounds the description asks for.
          # @parameter bits [Integer] how many bits to derive, which means 256 where the description says nothing.
          # @returns [Key] the key it derives to.
          def self.from_passphrase(passphrase, salt:, iterations:, bits: 256)
            derived = OpenSSL::KDF.pbkdf2_hmac(
              passphrase,
              salt: salt,
              iterations: iterations,
              length: bits / 8,
              hash: "SHA512",
            )

            self.new(derived)
          end

          # @parameter bytes [String] the raw key.
          def initialize(bytes)
            @bytes = bytes
          end

          # @attribute [String] the raw key, which is what is shown to a user and never sent.
          attr :bytes

          # Encrypt a secret under this key, named so that one key cannot read another's.
          #
          # @parameter name [String] what the secret is called, which is the account data type.
          # @parameter plaintext [String] the secret.
          # @returns [Hash] the counter, the ciphertext and the code over it.
          def encrypt(name, plaintext)
            aes, mac = self.derive(name)
            iv = self.class.counter

            ciphertext = self.cipher(:encrypt, aes, iv, plaintext)

            {
              iv: self.class.encode(iv),
              ciphertext: self.class.encode(ciphertext),
              mac: self.class.encode(OpenSSL::HMAC.digest("SHA256", mac, ciphertext)),
            }
          end

          # Read a secret, if the code over it is the one this key would have written.
          #
          # @parameter name [String] what the secret is called.
          # @parameter data [Hash] the counter, the ciphertext and the code.
          # @returns [String | nil] the secret, or nil when it was not this key which wrote it.
          def decrypt(name, data)
            aes, mac = self.derive(name)
            ciphertext = self.class.decode(data[:ciphertext])

            expected = OpenSSL::HMAC.digest("SHA256", mac, ciphertext)

            case OpenSSL.secure_compare(expected, self.class.decode(data[:mac]))
            in false
              nil
            in true
              self.cipher(:decrypt, aes, self.class.decode(data[:iv]), ciphertext)
            end
          end

          # Whether this key is the one a description was written by.
          #
          # @parameter iv [String] the counter from the description.
          # @parameter mac [String] the code from the description.
          # @returns [Boolean] whether they match.
          def correct?(iv:, mac:)
            # The description carries the code over a known message, so a wrong passphrase is caught before anything is decrypted with it.
            aes, key = self.derive("")

            ciphertext = self.cipher(:encrypt, aes, self.class.decode(iv), ZERO_MESSAGE)
            expected = OpenSSL::HMAC.digest("SHA256", key, ciphertext)

            OpenSSL.secure_compare(expected, self.class.decode(mac))
          end

          # What goes into account data to describe this key, so another device can arrive at it.
          #
          # @parameter name [String] what to call it to the user.
          # @parameter passphrase [Hash | nil] how it was derived, where it was.
          # @returns [Hash] the description.
          def description(name: nil, passphrase: nil)
            # It carries no key material: a passphrase description says how to derive one, and the check says whether the answer was right.
            aes, key = self.derive("")
            iv = self.class.counter

            ciphertext = self.cipher(:encrypt, aes, iv, ZERO_MESSAGE)

            {
              algorithm: ALGORITHM,
              name: name,
              iv: self.class.encode(iv),
              mac: self.class.encode(OpenSSL::HMAC.digest("SHA256", key, ciphertext)),
              passphrase: passphrase,
            }.compact
          end

          # @returns [String] the key as it is shown to a person, which is the only place it is.
          def to_s
            KeyRepresentation.encode(@bytes)
          end

          def inspect
            "\#<#{self.class}>"
          end

          # Sixteen random bytes, with the top bit of the counter cleared.
          #
          # @returns [String] the counter block.
          def self.counter
            # The specification asks for that to work around implementations which disagree about where the counter wraps.
            SecureRandom.bytes(16).tap do |iv|
              iv.setbyte(8, iv.getbyte(8) & 0x7f)
            end
          end

          # @parameter bytes [String] what to encode.
          # @returns [String] unpadded base64, which is what the specification asks for.
          def self.encode(bytes)
            Base64.strict_encode64(bytes).delete("=")
          end

          # Padded base64 is accepted too, because some clients write it.
          #
          # @parameter string [String] what to decode.
          # @returns [String] the bytes.
          def self.decode(string)
            Base64.decode64(string.to_s)
          end

          private

          # The two keys a name derives to: one to encrypt with, one to sign with.
          #
          # @parameter name [String] the name of the secret, or the empty string for the check.
          # @returns [Array(String, String)] the AES key and the MAC key.
          def derive(name)
            derived = OpenSSL::KDF.hkdf(@bytes, salt: ZERO_SALT, info: name, length: 64, hash: "SHA256")

            [derived.byteslice(0, 32), derived.byteslice(32, 32)]
          end

          # @parameter direction [Symbol] whether to encrypt or decrypt.
          # @parameter key [String] the AES key.
          # @parameter iv [String] the counter block.
          # @parameter data [String] what to put through it.
          # @returns [String] the result.
          def cipher(direction, key, iv, data)
            cipher = OpenSSL::Cipher.new("AES-256-CTR")
            cipher.public_send(direction)
            cipher.key = key
            cipher.iv = iv

            cipher.update(data) + cipher.final
          end
        end
      end
    end
  end
end
