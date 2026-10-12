# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "verification_key"

module Async
  module Matrix
    module Signatures
      # Where a verification key is looked up, which the third step of the check needs.
      #
      # A caller holding keys from somewhere else answers `verification_key` itself instead.
      class Keyring
        class << self
          # The keys a device published, which its owner's user ID signs with.
          #
          # @parameter device [E2EE::Device | Hash] the device, as the homeserver answered with it.
          # @returns [Keyring] a keyring holding its keys.
          def for_device(device)
            value = self.value_of(device)
            entity = value[:user_id] || value["user_id"]

            self.new.tap do |keyring|
              (value[:keys] || value["keys"] || {}).each do |key_id, key|
                keyring.add(entity, key_id, key)
              end
            end
          end

          # The keys a homeserver publishes for itself, which it signs its own name with.
          #
          # @parameter server_keys [Hash] the answer from `/_matrix/key/v2/server`.
          # @parameter expired [Boolean] whether to take the keys it has rotated away from too.
          # @returns [Keyring] a keyring holding its keys.
          def for_server(server_keys, expired: true)
            value = self.value_of(server_keys)
            entity = value[:server_name] || value["server_name"]
            published = [value[:verify_keys] || value["verify_keys"] || {}]

            if expired
              published << (value[:old_verify_keys] || value["old_verify_keys"] || {})
            end

            self.new.tap do |keyring|
              published.each do |keys|
                keys.each do |key_id, key|
                  keyring.add(entity, key_id, key[:key] || key["key"])
                end
              end
            end
          end

          # @parameter key_id [String] the signing key identifier the key is filed under.
          # @parameter key [String | VerificationKey] the key, as unpadded base64 or already read.
          # @returns [VerificationKey | nil] the key, where we can check its algorithm.
          def read(key_id, key)
            key.is_a?(VerificationKey) ? key : VerificationKey.parse(key_id.to_s, key)
          end

          # A representation carries what the server answered with, and a plain hash is already it.
          #
          # @parameter object [Object] the answer, however it was given.
          # @returns [Hash] the fields it holds.
          def value_of(object)
            object.respond_to?(:value) ? object.value : object
          end
        end

        def initialize
          @keys = {}
        end

        # @parameter entity [String] whose key it is, which is a server name or a user ID.
        # @parameter key_id [String] the signing key identifier, e.g. `ed25519:1`.
        # @parameter key [String | VerificationKey] the key, as unpadded base64 or already read.
        # @returns [Keyring] the keyring, so that keys can be added one after another.
        def add(entity, key_id, key)
          verification_key = self.class.read(key_id, key)

          if verification_key
            (@keys[entity.to_s] ||= {})[key_id.to_s] = verification_key
          end

          self
        end

        # @parameter entity [String] whose keys to answer with.
        # @returns [Hash] the keys it holds for that entity, by signing key identifier.
        def [](entity)
          @keys[entity.to_s] || {}
        end

        # @parameter entity [String] whose key it would be.
        # @parameter key_id [String] the signing key identifier wanted.
        # @returns [VerificationKey | nil] the key, where this keyring holds it.
        def verification_key(entity, key_id)
          self[entity][key_id.to_s]
        end

        # @returns [Array(String)] the entities this keyring holds a key for.
        def entities
          @keys.keys
        end

        def inspect
          "\#<#{self.class} #{@keys.transform_values(&:keys)}>"
        end
      end
    end
  end
end
