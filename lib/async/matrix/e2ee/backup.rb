# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"

require "vodozemac"

module Async
  module Matrix
    module E2EE
      # The key a server side backup is encrypted to.
      #
      # Anybody holding the public half can add to a backup, and only the private half reads it back.
      class Backup
        # The only backup algorithm the specification defines.
        ALGORITHM = "m.megolm_backup.v1.curve25519-aes-sha2"

        # @returns [Backup] a new key pair, whose private half the user must keep.
        def self.generate
          self.new(Vodozemac::PkDecryption.new)
        end

        # The backup a private key opens, which is what secret storage hands back.
        #
        # @parameter private_key [String] the private half, base64 encoded.
        # @parameter version [String | nil] which backup on the server it is.
        # @returns [Backup] the backup.
        def self.from_private_key(private_key, version: nil)
          self.new(Vodozemac::PkDecryption.from_base64(self.unpadded(private_key)), version: version)
        end

        # A backup which can be added to but not read, which is all that writing needs.
        #
        # @parameter public_key [String] the public half, base64 encoded.
        # @parameter version [String | nil] which backup on the server it is.
        # @returns [Backup] the backup.
        def self.from_public_key(public_key, version: nil)
          self.new(nil, public_key: self.unpadded(public_key), version: version)
        end

        # @parameter decryption [Vodozemac::PkDecryption | nil] the private half, when there is one.
        # @parameter public_key [String | nil] the public half, for a backup which has no private one.
        # @parameter version [String | nil] which backup on the server it is.
        def initialize(decryption, public_key: nil, version: nil)
          @decryption = decryption
          @public_key = public_key || decryption.public_key
          @version = version
        end

        # @attribute [String | nil] which backup on the server this is.
        attr :version

        # The same backup, known to be a particular one on the server.
        #
        # @parameter version [String] the version the server gave it.
        # @returns [Backup] the backup.
        def at(version)
          self.class.new(@decryption, public_key: @public_key, version: version)
        end

        # @returns [String] the public half, which goes into the backup's `auth_data`.
        def public_key
          @public_key
        end

        # @returns [String | nil] the private half, which belongs in secret storage.
        def private_key
          if self.private?
            @decryption.secret_key
          else
            nil
          end
        end

        # @returns [Boolean] whether this backup can be read as well as written to.
        def private?
          !@decryption.nil?
        end

        # What describes this backup to every other device, and what they check before writing to it.
        #
        # @returns [Hash] the authentication data, which a caller signs.
        def auth_data
          {public_key: self.public_key}
        end

        # One session, as the backup holds it.
        #
        # The fields outside `session_data` are what the server breaks a tie with, so they are sent in the clear deliberately.
        #
        # @parameter session [Hash] the session, as {Machine#export_for_backup} answers it.
        # @returns [Hash] what to send for it.
        def encrypt(session)
          {
            first_message_index: session[:first_message_index] || 0,
            forwarded_count: session[:forwarded_count] || 0,
            is_verified: session[:is_verified] || false,
            session_data: self.sealed(::JSON.dump(self.backed_up(session))),
          }
        end

        # Read one session back, if this is the key it was written to.
        #
        # @parameter session_data [Hash] the ciphertext, the code and the ephemeral key.
        # @returns [Hash | nil] the session, or nil when it does not read.
        def decrypt(session_data)
          unless self.private?
            raise ArgumentError, "This backup holds no private key, so nothing can be read from it!"
          end

          plaintext = self.opened(session_data)

          if plaintext
            ::JSON.parse(plaintext, symbolize_names: true)
          else
            nil
          end
        end

        def inspect
          "\#<#{self.class} #{self.public_key}#{self.private? ? " private" : ""}>"
        end

        # The specification carries base64 unpadded, and the binding refuses padding rather than ignoring it.
        #
        # @parameter string [String] what a server sent.
        # @returns [String] the same, with any padding taken off.
        def self.unpadded(string)
          string.to_s.delete("=")
        end

        private

        # What goes inside the ciphertext, which is the session and what is claimed about its sender.
        #
        # @parameter session [Hash] the session.
        # @returns [Hash] the fields the specification names.
        def backed_up(session)
          {
            algorithm: session[:algorithm] || Machine::MEGOLM,
            forwarding_curve25519_key_chain: session[:forwarding_curve25519_key_chain] || [],
            sender_key: session[:sender_key],
            sender_claimed_keys: session[:sender_claimed_keys] || {},
            session_key: session[:session_key],
            shared_history: session[:shared_history] || false,
          }
        end

        # Encrypt to this backup, with a key pair which the binding uses once and throws away.
        #
        # @parameter plaintext [String] the JSON to seal.
        # @returns [Hash] the ciphertext, the code, and the public half of the ephemeral key.
        def sealed(plaintext)
          ciphertext, mac, ephemeral = Vodozemac::PkEncryption.from_base64(@public_key).encrypt(plaintext)

          {ciphertext: ciphertext, mac: mac, ephemeral: ephemeral}
        end

        # The code over the ciphertext authenticates nothing, which is libolm's bug and the specification's warning.
        #
        # So a message which fails it was written to another key, rather than tampered with. See MSC4048 for the version which fixes it.
        #
        # @parameter session_data [Hash] the three parts the server holds.
        # @returns [String | nil] the plaintext, or nil when this is not the key it was written to.
        def opened(session_data)
          @decryption.decrypt(
            self.class.unpadded(session_data[:ciphertext]),
            self.class.unpadded(session_data[:mac]),
            self.class.unpadded(session_data[:ephemeral]),
          )
        rescue RuntimeError
          nil
        end
      end
    end
  end
end
