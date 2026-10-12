# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "vodozemac"

require_relative "canonical_json"

module Async
  module Matrix
    module E2EE
      # The three keys which make a user's identity, so that verifying a person once covers every device they have.
      #
      # The master key is the identity, the self signing key signs their own devices, and the user signing key signs other people's master keys.
      class CrossSigning
        # What each key is for, which the server and every other client reads it by.
        USAGE = {master: "master", self_signing: "self_signing", user_signing: "user_signing"}.freeze

        # One ed25519 key pair, which is all a cross signing key is.
        class Key
          # @returns [Key] a new key pair.
          def self.generate
            self.new(Vodozemac::Ed25519SecretKey.new)
          end

          # The key a secret from storage describes, which is how a second device comes by it.
          #
          # @parameter encoded [String] the private half, base64 encoded.
          # @returns [Key] the key.
          def self.from_base64(encoded)
            self.new(Vodozemac::Ed25519SecretKey.from_base64(self.unpadded(encoded)))
          end

          # @parameter key [Vodozemac::Ed25519SecretKey] the ed25519 key.
          def initialize(key)
            @key = key
          end

          # @returns [String] the public half, which is also how the key is named.
          def public_key
            @key.public_key
          end

          # @returns [String] the private half, which belongs in secret storage and nowhere else.
          def private_key
            @key.to_base64
          end

          # Sign an object, which is canonicalised first so that the order of its names cannot matter.
          #
          # @parameter object [Hash] what to sign.
          # @returns [String] the signature.
          def sign(object)
            @key.sign(CanonicalJSON.for_signing(object))
          end

          # @parameter object [Hash] the signed object.
          # @parameter signature [String] the signature to check.
          # @returns [Boolean] whether this key wrote it.
          def verify(object, signature)
            self.class.verify(self.public_key, object, signature)
          end

          # @parameter public_key [String] the key which is said to have signed it.
          # @parameter object [Hash] the signed object.
          # @parameter signature [String] the signature to check.
          # @returns [Boolean] whether that key wrote it.
          def self.verify(public_key, object, signature)
            Vodozemac.verify_signature(
              self.unpadded(public_key),
              CanonicalJSON.for_signing(object),
              self.unpadded(signature),
            )
          rescue RuntimeError
            false
          end

          # The specification carries base64 unpadded, and the binding refuses padding rather than ignoring it.
          #
          # @parameter string [String] what a server sent.
          # @returns [String] the same, with any padding taken off.
          def self.unpadded(string)
            string.to_s.delete("=")
          end

          def inspect
            "\#<#{self.class} #{self.public_key}>"
          end
        end

        # A whole new identity, which replaces any the user had.
        #
        # @parameter user_id [String] whose identity it is.
        # @returns [CrossSigning] the three keys.
        def self.generate(user_id)
          self.new(user_id, master: Key.generate, self_signing: Key.generate, user_signing: Key.generate)
        end

        # @parameter user_id [String] whose identity it is.
        # @parameter master [Key | nil] the master key.
        # @parameter self_signing [Key | nil] the key which signs their own devices.
        # @parameter user_signing [Key | nil] the key which signs other people's identities.
        def initialize(user_id, master: nil, self_signing: nil, user_signing: nil)
          @user_id = user_id
          @keys = {master: master, self_signing: self_signing, user_signing: user_signing}
        end

        # @attribute [String] whose identity this is.
        attr :user_id

        # @parameter name [Symbol] which of the three.
        # @returns [Key | nil] that key, if this device holds it.
        def [](name)
          @keys[name]
        end

        # Take on one of the three, which is what arrives from storage or a sibling device.
        #
        # @parameter name [Symbol] which of the three.
        # @parameter key [Key] the key.
        def []=(name, key)
          @keys[name] = key
        end

        # @returns [String | nil] the master public key, which is the user's identity.
        def master_key
          @keys[:master]&.public_key
        end

        # @returns [String | nil] the self signing public key.
        def self_signing_key
          @keys[:self_signing]&.public_key
        end

        # @returns [String | nil] the user signing public key.
        def user_signing_key
          @keys[:user_signing]&.public_key
        end

        # The master key as it is published, which the other two are signed by.
        #
        # @returns [Hash] the key object.
        def master
          self.object(:master)
        end

        # The self signing key as it is published, signed by the master key.
        #
        # @returns [Hash] the key object.
        def self_signing
          self.signed(self.object(:self_signing))
        end

        # The user signing key as it is published, signed by the master key.
        #
        # @returns [Hash] the key object.
        def user_signing
          self.signed(self.object(:user_signing))
        end

        # @returns [String | nil] the private master key, for secret storage.
        def private_master
          @keys[:master]&.private_key
        end

        # @returns [String | nil] the private self signing key, for secret storage.
        def private_self_signing
          @keys[:self_signing]&.private_key
        end

        # @returns [String | nil] the private user signing key, for secret storage.
        def private_user_signing
          @keys[:user_signing]&.private_key
        end

        # Sign a device's own keys with the self signing key, which is what makes it cross signed.
        #
        # @parameter device_keys [Hash] the device keys to sign.
        # @returns [Hash | nil] the signatures to upload, or nil without the key to write them.
        def sign_device(device_keys)
          self.signatures_for(:self_signing, device_keys) do |signature, key|
            {@user_id => {device_keys[:device_id] => {"ed25519:#{key}" => signature}}}
          end
        end

        # Sign another user's master key with the user signing key, which is what verifying them means.
        #
        # @parameter user_id [String] whose key it is.
        # @parameter master [Hash] their master key object.
        # @returns [Hash | nil] the signatures to upload, or nil without the key to write them.
        def sign_master(user_id, master)
          self.signatures_for(:user_signing, master) do |signature, key|
            {user_id => {master[:keys].each_value.first => {"ed25519:#{key}" => signature}}}
          end
        end

        def inspect
          "\#<#{self.class} #{@user_id} #{@keys.select{|_, key| key}.keys.join(", ")}>"
        end

        private

        # @parameter name [Symbol] which of the three.
        # @returns [Hash] the key object the server publishes.
        def object(name)
          key = @keys[name] or raise KeyError, "This identity holds no #{name} key!"

          {
            user_id: @user_id,
            usage: [USAGE.fetch(name)],
            keys: {"ed25519:#{key.public_key}" => key.public_key},
          }
        end

        # The same object, with the master key's signature over it.
        #
        # @parameter object [Hash] the key object.
        # @returns [Hash] the object, signed.
        def signed(object)
          master = @keys[:master] or raise KeyError, "This identity holds no master key to sign with!"

          object.merge(signatures: {@user_id => {"ed25519:#{master.public_key}" => master.sign(object)}})
        end

        # @parameter name [Symbol] which key to sign with.
        # @parameter object [Hash] what to sign.
        # @yields {|signature, key| ...} how to shape the answer.
        # @returns [Hash | nil] the signatures, or nil where this device holds no such key.
        def signatures_for(name, object)
          key = @keys[name]

          case key
          in Key => signing
            yield signing.sign(object), signing.public_key
          in nil
            nil
          end
        end
      end
    end
  end
end
