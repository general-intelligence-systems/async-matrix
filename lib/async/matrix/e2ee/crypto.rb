# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module E2EE
      # What encryption needs from a cryptographic implementation.
      #
      # This is the only place which touches key material, so it is the only place a binding is needed.
      class Crypto
        # @returns [Hash] the long lived public keys of this device, by algorithm.
        def identity_keys
          raise NotImplementedError, "An implementation must answer its identity keys!"
        end

        # @returns [Array(String)] the algorithms this implementation can encrypt with.
        def algorithms
          raise NotImplementedError, "An implementation must answer its algorithms!"
        end

        # Sign an object, which is canonicalised first.
        #
        # @parameter object [Hash] the object to sign.
        # @returns [String] the signature.
        def sign(object)
          raise NotImplementedError, "An implementation must sign!"
        end

        # @parameter object [Hash] the signed object.
        # @parameter key [String] the public key to verify against.
        # @parameter signature [String] the signature to check.
        # @returns [Boolean] whether it matches.
        def verify(object, key:, signature:)
          raise NotImplementedError, "An implementation must verify!"
        end

        # Generate one time keys, which are handed out to establish sessions.
        #
        # @parameter count [Integer] how many to generate.
        # @returns [Hash] the keys, by ID.
        def generate_one_time_keys(count)
          raise NotImplementedError, "An implementation must generate one time keys!"
        end

        # Generate the key a server hands out once the one time keys run out.
        #
        # @returns [Hash] the key, by ID.
        def generate_fallback_key
          raise NotImplementedError, "An implementation must generate a fallback key!"
        end

        # @returns [Hash] the fallback key, if one was generated.
        def fallback_key
          raise NotImplementedError, "An implementation must answer its fallback key!"
        end

        # @returns [Hash] the one time keys which have not been published.
        def one_time_keys
          raise NotImplementedError, "An implementation must answer its one time keys!"
        end

        # Forget the one time keys which were published, so that none is published twice.
        #
        # @returns [Hash] the keys which are left, which is none.
        def published_one_time_keys!
          raise NotImplementedError, "An implementation must forget published keys!"
        end

        # @returns [Integer] how many one time keys the server should hold.
        def one_time_key_target
          raise NotImplementedError, "An implementation must answer its target!"
        end

        # Whether there is already an Olm session with a device.
        #
        # @parameter identity_key [String] the device's curve25519 key.
        # @returns [Boolean] whether one is open.
        def session?(identity_key)
          raise NotImplementedError, "An implementation must answer whether it has a session!"
        end

        # Open an Olm session with a device, using a one time key claimed for it.
        #
        # @parameter identity_key [String] the device's curve25519 key.
        # @parameter one_time_key [String] the key claimed from the server.
        # @returns [String] the ID of the session.
        def open_session(identity_key:, one_time_key:)
          raise NotImplementedError, "An implementation must open a session!"
        end

        # Adopt the Olm session a device opened with us, which arrives as a pre-key message.
        #
        # @parameter identity_key [String] the device's curve25519 key.
        # @parameter body [String] the pre-key message.
        # @returns [String] the plaintext it carried.
        def accept_session(identity_key:, body:)
          raise NotImplementedError, "An implementation must accept a session!"
        end

        # Encrypt for one device, which is how every key is delivered.
        #
        # @parameter identity_key [String] the device to encrypt for.
        # @parameter plaintext [String] the canonical JSON of the event.
        # @returns [Tuple(Integer, String)] the message type, and the body.
        def encrypt_to_device(identity_key, plaintext)
          raise NotImplementedError, "An implementation must encrypt to a device!"
        end

        # @parameter identity_key [String] the device which sent it.
        # @parameter type [Integer] 0 for a pre-key message, 1 for a normal one.
        # @parameter body [String] the message.
        # @returns [String] the plaintext.
        def decrypt_from_device(identity_key, type:, body:)
          raise NotImplementedError, "An implementation must decrypt from a device!"
        end

        # Begin a session for a room, which this device encrypts with.
        #
        # @parameter room_id [String] the room.
        # @returns [Hash] the session, with its ID and the key which shares it.
        def create_outbound_session(room_id)
          raise NotImplementedError, "An implementation must create a session!"
        end

        # The session this device is currently encrypting a room with, if there is one.
        #
        # @parameter room_id [String] the room.
        # @returns [Hash | nil] the session, with its ID and the key which shares it.
        def session_for(room_id)
          raise NotImplementedError, "An implementation must answer its session!"
        end

        # Accept a session another device shared.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the ID of the session.
        # @parameter session_key [String] the key which was shared.
        def create_inbound_session(room_id, session_id:, session_key:)
          raise NotImplementedError, "An implementation must accept a session!"
        end

        # Accept a session which carries no signature: forwarded, restored, or exported.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the ID of the session.
        # @parameter exported_key [String] the exported key.
        def import_inbound_session(room_id, session_id:, exported_key:)
          raise NotImplementedError, "An implementation must import a session!"
        end

        # Export a session, to forward it or to back it up.
        #
        # @parameter session_id [String] the session.
        # @parameter index [Integer] the index to export from.
        # @returns [String | nil] the key, or nil when the ratchet is already past that index.
        def export_session(session_id, index:)
          raise NotImplementedError, "An implementation must export a session!"
        end

        # @parameter room_id [String] the room.
        # @parameter plaintext [String] the canonical JSON of the event to encrypt.
        # @returns [String] the ciphertext.
        def encrypt(room_id, plaintext)
          raise NotImplementedError, "An implementation must encrypt!"
        end

        # The index is what a caller rejects a replayed message by.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session the message belongs to.
        # @parameter ciphertext [String] the message.
        # @returns [Tuple(String, Integer)] the plaintext, and the index it was sent at.
        def decrypt(room_id, session_id:, ciphertext:)
          raise NotImplementedError, "An implementation must decrypt!"
        end

        # Everything this device must remember, as one string.
        #
        # @parameter pickle_key [String] the key to encrypt it with.
        # @returns [String] the state.
        def dump(pickle_key)
          raise NotImplementedError, "An implementation must dump its state!"
        end

        # @parameter dumped [String] what {#dump} wrote.
        # @parameter pickle_key [String] the key it was written with.
        # @returns [Crypto] the device it describes.
        def self.load(dumped, pickle_key)
          raise NotImplementedError, "An implementation must load its state!"
        end
      end
    end
  end
end
