# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "base64"
require "digest"
require "json"
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
      # Its ciphertext is reversible, so both ratchets can be driven before any binding.
      class Plaintext < Crypto
        # The algorithm a room is encrypted with.
        MEGOLM = "m.megolm.v1.aes-sha2"

        # The algorithm a device is encrypted to, which is how every key travels.
        OLM = "m.olm.v1.curve25519-aes-sha2"

        MARKER = "plaintext"

        # How many sessions to keep with one device, which is the fewest the specification allows.
        SESSIONS = 4

        # @parameter one_time_key_target [Integer] how many one time keys to keep published.
        def initialize(one_time_key_target: 50)
          @one_time_key_target = one_time_key_target

          @curve25519 = self.class.random
          @ed25519 = self.class.random

          @one_time_keys = {}
          @fallback_key = {}

          # The Olm half: the sessions with each device, by that device's identity key.
          @sessions = {}

          # The Megolm half: one outbound session per room, and one inbound session per session ID.
          @outbound = {}
          @inbound = {}
        end

        # @returns [String] a value which looks like a key without being one.
        def self.random
          Base64.urlsafe_encode64(SecureRandom.bytes(32), padding: false)
        end

        # @parameter plaintext [String] what to disguise.
        # @returns [String] the plaintext, marked so it is never mistaken for ciphertext.
        def self.disguise(plaintext)
          "#{MARKER}:#{Base64.urlsafe_encode64(plaintext, padding: false)}"
        end

        # @parameter body [String] what {.disguise} wrote.
        # @returns [String] the plaintext it carried.
        def self.reverse(body)
          marker, encoded = body.split(":", 2)

          unless marker == MARKER
            raise ArgumentError, "This is not a plaintext message!"
          end

          Base64.urlsafe_decode64(encoded)
        end

        # @returns [Hash] the long lived public keys of this device, by algorithm.
        def identity_keys
          {curve25519: @curve25519, ed25519: @ed25519}
        end

        # Both, because a device which encrypts a room must accept the keys for it over Olm.
        #
        # @returns [Array(String)] the algorithms this implementation can encrypt with.
        def algorithms
          [OLM, MEGOLM]
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

        # The key a server hands out once the one time keys are exhausted.
        #
        # @returns [Hash] the key, by ID.
        def generate_fallback_key
          @fallback_key = {"signed_curve25519:#{SecureRandom.alphanumeric(6)}" => self.class.random}
        end

        # @returns [Hash] the fallback key, if one was generated.
        def fallback_key
          @fallback_key
        end

        # @parameter identity_key [String] the device's curve25519 key.
        # @returns [Boolean] whether a session with it is open.
        def session?(identity_key)
          @sessions.key?(identity_key)
        end

        # @parameter identity_key [String] the device's curve25519 key.
        # @parameter one_time_key [String] the key claimed from the server.
        # @returns [String] the ID of the session.
        def open_session(identity_key:, one_time_key:)
          self.remember(identity_key, received: false)[:session_id]
        end

        # @parameter identity_key [String] the device's curve25519 key.
        # @parameter body [String] the pre-key message.
        # @returns [String] the plaintext it carried.
        def accept_session(identity_key:, body:)
          self.remember(identity_key, received: true)

          self.class.reverse(body)
        end

        # @parameter identity_key [String] the device to encrypt for.
        # @parameter plaintext [String] the canonical JSON of the event.
        # @returns [Tuple(Integer, String)] the message type, and the body.
        def encrypt_to_device(identity_key, plaintext)
          session = self.sessions!(identity_key).last
          body = self.class.disguise(plaintext)

          # Olm sends pre-key messages until one arrives over the session, which is what adopts it.
          if session[:received]
            [1, body]
          else
            [0, body]
          end
        end

        # @parameter identity_key [String] the device which sent it.
        # @parameter type [Integer] 0 for a pre-key message, 1 for a normal one.
        # @parameter body [String] the message.
        # @returns [String] the plaintext.
        def decrypt_from_device(identity_key, type:, body:)
          sessions = self.sessions!(identity_key)
          sessions.last[:received] = true

          self.class.reverse(body)
        end

        # @parameter room_id [String] the room.
        # @returns [Hash] the session, with its ID and the key which shares it.
        def create_outbound_session(room_id)
          {session_id: SecureRandom.alphanumeric(12), session_key: self.class.random, message_index: 0}.tap do |session|
            @outbound[room_id] = session

            # A device reads the messages it sent, which come back in a sync batch like anybody else's:
            @inbound[session[:session_id]] = {room_id: room_id, session_key: session[:session_key], first_known_index: 0}
          end
        end

        # @parameter room_id [String] the room.
        # @returns [Hash | nil] the session this device encrypts that room with.
        def session_for(room_id)
          @outbound[room_id]
        end

        # @parameter room_id [String] the room.
        # @parameter session_id [String] the ID of the session.
        # @parameter session_key [String] the key which was shared.
        def create_inbound_session(room_id, session_id:, session_key:)
          @inbound[session_id] = {room_id: room_id, session_key: session_key, first_known_index: 0}
        end

        # It begins where it was exported from, so anything earlier stays unreadable.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the ID of the session.
        # @parameter exported_key [String] the exported key.
        # @parameter index [Integer] the index it was exported at.
        def import_inbound_session(room_id, session_id:, exported_key:, index: 0)
          @inbound[session_id] = {room_id: room_id, session_key: exported_key, first_known_index: index, imported: true}
        end

        # @parameter session_id [String] the session.
        # @parameter index [Integer] the index to export from.
        # @returns [String | nil] the key, or nil when the ratchet is already past that index.
        def export_session(session_id, index:)
          session = self.inbound!(session_id)

          if index < session[:first_known_index]
            nil
          else
            session[:session_key]
          end
        end

        # @parameter room_id [String] the room.
        # @parameter plaintext [String] the canonical JSON to encrypt.
        # @returns [String] the ciphertext, which is the plaintext in disguise.
        def encrypt(room_id, plaintext)
          session = @outbound[room_id] or raise KeyError, "No session for #{room_id}!"
          session[:message_index] += 1

          self.class.disguise(plaintext)
        end

        # The room is carried by the session, so a homeserver cannot move a message between rooms.
        #
        # @parameter room_id [String] the room it arrived in.
        # @parameter session_id [String] the session it belongs to.
        # @parameter ciphertext [String] the message.
        # @returns [Tuple(String, Integer)] the plaintext, and the index it was sent at.
        def decrypt(room_id, session_id:, ciphertext:)
          session = self.inbound!(session_id)

          unless session[:room_id] == room_id
            raise ArgumentError, "Session #{session_id} belongs to #{session[:room_id]}, not #{room_id}!"
          end

          [self.class.reverse(ciphertext), session[:first_known_index]]
        end

        # @parameter pickle_key [String] the key to encrypt it with, which is ignored here.
        # @returns [String] the state.
        def dump(pickle_key)
          ::JSON.dump(
            one_time_key_target: @one_time_key_target,
            curve25519: @curve25519,
            ed25519: @ed25519,
            one_time_keys: @one_time_keys,
            fallback_key: @fallback_key,
            sessions: @sessions,
            outbound: @outbound,
            inbound: @inbound,
          )
        end

        # @parameter dumped [String] what {#dump} wrote.
        # @parameter pickle_key [String] the key it was written with, which is ignored here.
        # @returns [Plaintext] the device it describes.
        def self.load(dumped, pickle_key)
          value = ::JSON.parse(dumped, symbolize_names: true)

          self.new(one_time_key_target: value[:one_time_key_target]).tap do |crypto|
            crypto.restore!(value)
          end
        end

        # Take on the state {.load} read, which is its only caller.
        #
        # @parameter value [Hash] the state.
        def restore!(value)
          @curve25519 = value[:curve25519]
          @ed25519 = value[:ed25519]
          @one_time_keys = self.class.named(value[:one_time_keys])
          @fallback_key = self.class.named(value[:fallback_key])
          @sessions = self.class.named(value[:sessions])
          @outbound = self.class.named(value[:outbound])
          @inbound = self.class.named(value[:inbound])
        end

        # JSON has only string names, and every key here is a key or an ID rather than a symbol.
        #
        # @parameter value [Hash] what was parsed.
        # @returns [Hash] the same, named by string.
        def self.named(value)
          value.transform_keys(&:to_s)
        end

        private

        # Keep the newest sessions with a device, discarding the oldest beyond what is allowed.
        #
        # @parameter identity_key [String] the device.
        # @parameter received [Boolean] whether a message has arrived over the new session.
        # @returns [Hash] the session which was opened.
        def remember(identity_key, received:)
          sessions = (@sessions[identity_key] ||= [])
          sessions.push({session_id: SecureRandom.alphanumeric(12), received: received})

          while sessions.size > SESSIONS
            sessions.shift
          end

          sessions.last
        end

        # @parameter identity_key [String] the device.
        # @returns [Array(Hash)] the sessions with it, oldest first.
        def sessions!(identity_key)
          @sessions[identity_key] or raise KeyError, "No Olm session with #{identity_key}!"
        end

        # @parameter session_id [String] the session.
        # @returns [Hash] the inbound session, which must have been accepted.
        def inbound!(session_id)
          @inbound[session_id] or raise KeyError, "No session #{session_id}!"
        end
      end
    end
  end
end
