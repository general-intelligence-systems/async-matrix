# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"

require_relative "canonical_json"
require_relative "crypto"

# The native extension, which nothing else under `lib` loads.
require_relative "../async_matrix_e2ee"

module Async
  module Matrix
    module E2EE
      # Encryption, over vodozemac.
      #
      # Every key crossing this boundary is a base64 string, because that is how Matrix moves keys.
      class Vodozemac < Crypto
        # The algorithm a room is encrypted with.
        MEGOLM = "m.megolm.v1.aes-sha2"

        # The algorithm a device is encrypted to, which is how every key travels.
        OLM = "m.olm.v1.curve25519-aes-sha2"

        # How many sessions to keep with one device, which is the fewest the specification allows.
        SESSIONS = 4

        # What a one time key is named by, which the server and the binding disagree about.
        ALGORITHM = "signed_curve25519"

        # @parameter account [Account] the long lived identity, which holds the one time keys.
        def initialize(account: Account.new)
          @account = account

          # Several sessions may exist with one device, newest last, because a message may arrive over any of them.
          @sessions = {}

          @outbound = {}
          @inbound = {}
        end

        # @attribute [Account] the identity this device signs and opens sessions with.
        attr :account

        # @returns [Hash] the long lived public keys of this device, by algorithm.
        def identity_keys
          {curve25519: @account.curve25519_key, ed25519: @account.ed25519_key}
        end

        # Both, because a device which encrypts a room must accept the keys for it over Olm.
        #
        # @returns [Array(String)] the algorithms this implementation can encrypt with.
        def algorithms
          [OLM, MEGOLM]
        end

        # Half of what the server will hold, which leaves room to publish more before running out.
        #
        # @returns [Integer] how many one time keys to keep published.
        def one_time_key_target
          @account.max_number_of_one_time_keys / 2
        end

        # @parameter object [Hash] the object to sign.
        # @returns [String] the signature, over the canonical form.
        def sign(object)
          @account.sign(CanonicalJSON.for_signing(object))
        end

        # @parameter object [Hash] the signed object.
        # @parameter key [String] the public key to verify against.
        # @parameter signature [String] the signature to check.
        # @returns [Boolean] whether it matches.
        def verify(object, key:, signature:)
          E2EE.verify_signature(key, CanonicalJSON.for_signing(object), signature)
        end

        # @parameter count [Integer] how many to generate.
        # @returns [Hash] the keys, by ID.
        def generate_one_time_keys(count)
          @account.generate_one_time_keys(count)

          self.one_time_keys
        end

        # @returns [Hash] the one time keys which have not been published.
        def one_time_keys
          self.class.named(@account.one_time_keys)
        end

        # Forget the one time keys which were published, so that none is published twice.
        #
        # @returns [Hash] the keys which are left, which is none.
        def published_one_time_keys!
          @account.mark_keys_as_published

          self.one_time_keys
        end

        # The key a server hands out once the one time keys are exhausted.
        #
        # @returns [Hash] the key, by ID.
        def generate_fallback_key
          @account.generate_fallback_key

          self.fallback_key
        end

        # @returns [Hash] the fallback key, if one was generated.
        def fallback_key
          self.class.named(@account.fallback_key)
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
          session = @account.create_outbound_session(identity_key, one_time_key)

          self.remember(identity_key, session)

          session.session_id
        end

        # @parameter identity_key [String] the device's curve25519 key.
        # @parameter body [String] the pre-key message.
        # @returns [String] the plaintext it carried.
        def accept_session(identity_key:, body:)
          session, plaintext = @account.create_inbound_session(identity_key, body)

          self.remember(identity_key, session)

          plaintext
        end

        # The binding answers the message type, which is 0 until the session has received one.
        #
        # @parameter identity_key [String] the device to encrypt for.
        # @parameter plaintext [String] the canonical JSON of the event.
        # @returns [Tuple(Integer, String)] the message type, and the body.
        def encrypt_to_device(identity_key, plaintext)
          self.sessions!(identity_key).last.encrypt(plaintext)
        end

        # A message may arrive over any session the device opened, so each is tried, newest first.
        #
        # @parameter identity_key [String] the device which sent it.
        # @parameter type [Integer] 0 for a pre-key message, 1 for a normal one.
        # @parameter body [String] the message.
        # @returns [String] the plaintext.
        def decrypt_from_device(identity_key, type:, body:)
          sessions = self.sessions!(identity_key)
          plaintext = nil

          session = sessions.reverse_each.find do |candidate|
            plaintext = self.attempt(candidate, type, body)
          end

          unless session
            raise ArgumentError, "No session with #{identity_key} could read this message!"
          end

          # The session a message arrived over is the one to answer over, so it becomes the newest.
          sessions.delete(session)
          sessions.push(session)

          plaintext
        end

        # @parameter room_id [String] the room.
        # @returns [Hash] the session, with its ID and the key which shares it.
        def create_outbound_session(room_id)
          group = GroupSession.new

          @outbound[room_id] = group

          # A device reads the messages it sent, so its own session is kept as an inbound one too:
          @inbound[group.session_id] = {room_id: room_id, session: InboundGroupSession.new(group.session_key)}

          {session_id: group.session_id, session_key: group.session_key, message_index: group.message_index}
        end

        # @parameter room_id [String] the room.
        # @returns [Hash | nil] the session this device encrypts that room with.
        def session_for(room_id)
          group = @outbound[room_id]

          if group
            {session_id: group.session_id, session_key: group.session_key, message_index: group.message_index}
          else
            nil
          end
        end

        # @parameter room_id [String] the room.
        # @parameter session_id [String] the ID of the session.
        # @parameter session_key [String] the key which was shared.
        def create_inbound_session(room_id, session_id:, session_key:)
          @inbound[session_id] = {room_id: room_id, session: InboundGroupSession.new(session_key)}
        end

        # An exported key carries no signature, so the session it builds is trusted no further than whoever sent it.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the ID of the session.
        # @parameter exported_key [String] the exported key.
        def import_inbound_session(room_id, session_id:, exported_key:)
          session = InboundGroupSession.import(exported_key)

          @inbound[session_id] = {room_id: room_id, session: session, imported: true}
        end

        # @parameter session_id [String] the session.
        # @parameter index [Integer] the index to export from.
        # @returns [String | nil] the key, or nil when the ratchet is already past that index.
        def export_session(session_id, index:)
          self.inbound!(session_id)[:session].export_at(index)
        end

        # @parameter room_id [String] the room.
        # @parameter plaintext [String] the canonical JSON to encrypt.
        # @returns [String] the ciphertext.
        def encrypt(room_id, plaintext)
          group = @outbound[room_id] or raise KeyError, "No session for #{room_id}!"

          group.encrypt(plaintext)
        end

        # The room is carried by the session, so a homeserver cannot move a message between rooms.
        #
        # @parameter room_id [String] the room it arrived in.
        # @parameter session_id [String] the session it belongs to.
        # @parameter ciphertext [String] the message.
        # @returns [Tuple(String, Integer)] the plaintext, and the index it was sent at.
        def decrypt(room_id, session_id:, ciphertext:)
          known = self.inbound!(session_id)

          unless known[:room_id] == room_id
            raise ArgumentError, "Session #{session_id} belongs to #{known[:room_id]}, not #{room_id}!"
          end

          known[:session].decrypt(ciphertext)
        end

        # Every key is encrypted by the binding before it reaches this string.
        #
        # @parameter pickle_key [String] a 32 byte key.
        # @returns [String] the state.
        def dump(pickle_key)
          ::JSON.dump(
            account: @account.pickle(pickle_key),
            sessions: @sessions.transform_values{|sessions| sessions.map{|session| session.pickle(pickle_key)}},
            outbound: @outbound.transform_values{|group| group.pickle(pickle_key)},
            inbound: @inbound.transform_values{|known| self.class.dumped(known, pickle_key)},
          )
        end

        # @parameter dumped [String] what {#dump} wrote.
        # @parameter pickle_key [String] the 32 byte key it was written with.
        # @returns [Vodozemac] the device it describes.
        def self.load(dumped, pickle_key)
          value = ::JSON.parse(dumped, symbolize_names: true)

          self.new(account: Account.from_pickle(value[:account], pickle_key)).tap do |crypto|
            crypto.restore!(value, pickle_key)
          end
        end

        # Take on the state {.load} read, which is its only caller.
        #
        # @parameter value [Hash] the state.
        # @parameter pickle_key [String] the key it was written with.
        def restore!(value, pickle_key)
          @sessions = value[:sessions].each_with_object({}) do |(identity_key, pickles), sessions|
            sessions[identity_key.to_s] = pickles.map{|pickle| Session.from_pickle(pickle, pickle_key)}
          end

          @outbound = value[:outbound].each_with_object({}) do |(room_id, pickle), outbound|
            outbound[room_id.to_s] = GroupSession.from_pickle(pickle, pickle_key)
          end

          @inbound = value[:inbound].each_with_object({}) do |(session_id, known), inbound|
            inbound[session_id.to_s] = self.class.restored(known, pickle_key)
          end
        end

        # @parameter known [Hash] the inbound session, and what is remembered about it.
        # @parameter pickle_key [String] the key to encrypt it with.
        # @returns [Hash] the same, with the session pickled.
        def self.dumped(known, pickle_key)
          {room_id: known[:room_id], imported: known[:imported], session: known[:session].pickle(pickle_key)}
        end

        # @parameter known [Hash] what {.dumped} wrote.
        # @parameter pickle_key [String] the key it was written with.
        # @returns [Hash] the same, with the session restored.
        def self.restored(known, pickle_key)
          session = InboundGroupSession.from_pickle(known[:session], pickle_key)

          {room_id: known[:room_id], imported: known[:imported], session: session}
        end

        # The binding names a key by its ID alone, where the server names it by algorithm too.
        #
        # @parameter keys [Hash] the keys, by ID.
        # @returns [Hash] the same, named as a server claims them.
        def self.named(keys)
          keys.transform_keys{|id| "#{ALGORITHM}:#{id}"}
        end

        private

        # Keep the newest sessions with a device, discarding the oldest beyond what is allowed.
        #
        # @parameter identity_key [String] the device.
        # @parameter session [Session] the session to keep.
        def remember(identity_key, session)
          sessions = (@sessions[identity_key] ||= [])
          sessions.push(session)

          while sessions.size > SESSIONS
            sessions.shift
          end
        end

        # @parameter identity_key [String] the device.
        # @returns [Array(Session)] the sessions with it, oldest first.
        def sessions!(identity_key)
          @sessions[identity_key] or raise KeyError, "No Olm session with #{identity_key}!"
        end

        # @parameter session_id [String] the session.
        # @returns [Hash] the inbound session, which must have been accepted.
        def inbound!(session_id)
          @inbound[session_id] or raise KeyError, "No session #{session_id}!"
        end

        # @parameter session [Session] the session to try.
        # @parameter type [Integer] the message type.
        # @parameter body [String] the message.
        # @returns [String | nil] the plaintext, or nil when this session cannot read it.
        def attempt(session, type, body)
          session.decrypt(type, body)
        rescue RuntimeError
          nil
        end
      end
    end
  end
end
