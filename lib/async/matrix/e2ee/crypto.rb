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

        # @parameter room_id [String] the room.
        # @parameter plaintext [String] the canonical JSON of the event to encrypt.
        # @returns [String] the ciphertext.
        def encrypt(room_id, plaintext)
          raise NotImplementedError, "An implementation must encrypt!"
        end

        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session the message belongs to.
        # @parameter ciphertext [String] the message.
        # @returns [String] the plaintext.
        def decrypt(room_id, session_id:, ciphertext:)
          raise NotImplementedError, "An implementation must decrypt!"
        end
      end
    end
  end
end
