# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "base64"
require "digest"
require "securerandom"

require_relative "canonical_json"
require_relative "crypto"

module Async
  module Matrix
    module E2EE
      # An implementation which encrypts nothing.
      #
      # It is not encryption, and says so in every message it writes.
      #
      # Its ciphertext is reversible, so the flow can be driven before any binding.
      class Plaintext < Crypto
        ALGORITHM = "m.megolm.v1.aes-sha2"

        MARKER = "plaintext"

        # @parameter one_time_key_target [Integer] how many one time keys to keep published.
        def initialize(one_time_key_target: 50)
          @one_time_key_target = one_time_key_target

          @curve25519 = self.class.random
          @ed25519 = self.class.random

          @one_time_keys = {}
          @outbound = {}
          @inbound = {}
        end

        # @returns [String] a value which looks like a key without being one.
        def self.random
          Base64.urlsafe_encode64(SecureRandom.bytes(32), padding: false)
        end

        # @returns [Hash] the long lived public keys of this device, by algorithm.
        def identity_keys
          {curve25519: @curve25519, ed25519: @ed25519}
        end

        # @returns [Array(String)] the algorithms this implementation can encrypt with.
        def algorithms
          [ALGORITHM]
        end

        # @returns [Integer] how many one time keys the server should hold.
        def one_time_key_target
          @one_time_key_target
        end

        # @parameter object [Hash] the object to sign.
        # @returns [String] a digest of its canonical form, which stands in for a signature.
        def sign(object)
          "#{MARKER}:#{Digest::SHA256.base64digest(CanonicalJSON.for_signing(object))}"
        end

        # @parameter object [Hash] the signed object.
        # @parameter key [String] the public key, which is not used here.
        # @parameter signature [String] the signature to check.
        # @returns [Boolean] whether it matches.
        def verify(object, key:, signature:)
          signature == self.sign(object)
        end

        # @parameter count [Integer] how many to generate.
        # @returns [Hash] the keys, by ID.
        def generate_one_time_keys(count)
          count.times do
            @one_time_keys["signed_curve25519:#{SecureRandom.alphanumeric(6)}"] = self.class.random
          end

          @one_time_keys
        end

        # @returns [Hash] the one time keys which have not been published.
        def one_time_keys
          @one_time_keys
        end

        # Forget the one time keys which were published, so that none is published twice.
        #
        # @returns [Hash] the keys which are left, which is none.
        def published_one_time_keys!
          @one_time_keys = {}
        end

        # @parameter room_id [String] the room.
        # @returns [Hash] the session, with its ID and the key which shares it.
        def create_outbound_session(room_id)
          {session_id: SecureRandom.alphanumeric(12), session_key: self.class.random}.tap do |session|
            @outbound[room_id] = session

            # A device reads the messages it sent, which come back in a sync batch like anybody else's:
            @inbound[[room_id, session[:session_id]]] = session
          end
        end

        # @parameter room_id [String] the room.
        # @parameter session_id [String] the ID of the session.
        # @parameter session_key [String] the key which was shared.
        def create_inbound_session(room_id, session_id:, session_key:)
          @inbound[[room_id, session_id]] = {session_id: session_id, session_key: session_key}
        end

        # @parameter room_id [String] the room.
        # @returns [Hash | nil] the session this device encrypts that room with.
        def session_for(room_id)
          @outbound[room_id]
        end

        # @parameter room_id [String] the room.
        # @parameter plaintext [String] the canonical JSON to encrypt.
        # @returns [String] the ciphertext, which is the plaintext in disguise.
        def encrypt(room_id, plaintext)
          "#{MARKER}:#{Base64.urlsafe_encode64(plaintext, padding: false)}"
        end

        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session the message belongs to.
        # @parameter ciphertext [String] the message.
        # @returns [String] the plaintext.
        def decrypt(room_id, session_id:, ciphertext:)
          unless @inbound.key?([room_id, session_id])
            raise KeyError, "No session #{session_id} for #{room_id}!"
          end

          marker, encoded = ciphertext.split(":", 2)

          unless marker == MARKER
            raise ArgumentError, "This is not a plaintext message!"
          end

          Base64.urlsafe_decode64(encoded)
        end
      end
    end
  end
end
