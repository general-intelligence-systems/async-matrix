# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "console"

require_relative "secret_storage"

module Async
  module Matrix
    module E2EE
      # The private keys a device holds, and what it would write them to the server as.
      #
      # It makes no request: a caller hands it the account data, and it answers with what to send.
      class Secrets
        def initialize
          # The secrets this device has opened, which never leave it in the clear.
          @held = {}

          # The description of the account's storage, and the key which opens it.
          @description = nil
          @key_id = nil
          @key = nil

          # What this device asked its siblings for, so that an answer can be matched to a question.
          @asked = {}
        end

        # @attribute [String | nil] which key the account's storage is encrypted under.
        attr :key_id

        # Note the account's storage, so that a passphrase has something to open.
        #
        # @parameter key_id [String] the ID of the default key.
        # @parameter description [Hash] what `m.secret_storage.key.<id>` said.
        def describe(key_id, description)
          @key_id = key_id
          @description = description
        end

        # Note a secret as the account data holds it, sealed under the storage key.
        #
        # @parameter name [String] what the secret is called.
        # @parameter encrypted [Hash] the `encrypted` property, by key ID.
        def sealed(name, encrypted)
          (@sealed ||= {})[name] = encrypted
        end

        # Open the storage with a passphrase, and read whatever was sealed under it.
        #
        # @parameter passphrase [String] what the user typed.
        # @returns [Boolean] whether it opened.
        def unlock(passphrase)
          case @description
          in {passphrase: {algorithm: SecretStorage::PBKDF2, salt: String => salt, iterations: Integer => iterations, **rest}}
            key = SecretStorage::Key.from_passphrase(passphrase, salt: salt, iterations: iterations, bits: rest.fetch(:bits, 256))

            self.opened(key)
          in nil
            Console.warn(self, "There is no storage to open: nothing has described one.")

            false
          else
            Console.warn(self, "This storage was not derived from a passphrase.", key_id: @key_id)

            false
          end
        end

        # Open the storage with the key itself, which is what a user typed or a sibling sent.
        #
        # @parameter key [SecretStorage::Key] the key.
        # @returns [Boolean] whether it is the right one.
        def opened(key)
          case @description
          in {iv: String => iv, mac: String => mac} unless key.correct?(iv: iv, mac: mac)
            Console.warn(self, "That key does not open this storage.", key_id: @key_id)

            false
          else
            @key = key

            self.read_sealed

            true
          end
        end

        # @returns [Boolean] whether this device can read and write the account's storage.
        def open?
          !@key.nil?
        end

        # Take a secret this device has come by, however it came by it.
        #
        # @parameter name [String] what it is called.
        # @parameter secret [String | nil] the secret.
        def accept(name, secret)
          case secret
          in String => held
            @held[name] = held

            Console.debug(self, "Holding a secret.", name: name)
          in nil
            Console.warn(self, "Nothing to hold for a secret.", name: name)
          end
        end

        # @parameter name [String] what it is called.
        # @returns [String | nil] the secret, if this device holds it.
        def held(name)
          @held[name]
        end

        # What to write to account data to keep these secrets on the server.
        #
        # @parameter secrets [Hash] the secrets, by name.
        # @returns [Hash] the account data to set, by type.
        def store(secrets)
          secrets.each_with_object({}) do |(name, secret), written|
            @held[name.to_s] = secret

            # Without a storage key there is nowhere to put it, so it is held for this session and no further.
            if self.open?
              written[name.to_s] = {encrypted: {@key_id => @key.encrypt(name.to_s, secret)}}
            else
              Console.warn(self, "Holding a secret which cannot be written: this account has no storage open.", name: name)
            end
          end
        end

        # Read a secret which was sealed under this storage, now that it is open.
        #
        # @parameter name [String] what it is called.
        # @returns [String | nil] the secret, or nil where it is not there or does not read.
        def load(name)
          case {open: self.open?, sealed: (@sealed || {})[name]}
          in {open: true, sealed: Hash => encrypted} if encrypted.key?(@key_id.to_sym)
            @key.decrypt(name, encrypted[@key_id.to_sym]).tap do |secret|
              self.accept(name, secret)
            end
          else
            @held[name]
          end
        end

        # Note that this device has asked its siblings for a secret.
        #
        # @parameter request_id [String] the ID of the request.
        # @parameter name [String] what was asked for.
        def asking(request_id, name)
          @asked[request_id] = name
        end

        # @parameter request_id [String] the ID of the request.
        # @returns [String | nil] what was asked for under that ID.
        def requested(request_id)
          @asked[request_id]
        end

        # Whether this is an answer to something we asked, over a channel which proves who sent it.
        #
        # A secret arriving unbidden is somebody trying their luck, so it is never taken.
        #
        # @parameter request_id [String] the ID the answer carries.
        # @parameter over [Async::Matrix::Events::Envelope | nil] the event it arrived in.
        # @returns [Boolean] whether to believe it.
        def asked?(request_id, over: nil)
          case {asked: @asked.key?(request_id), over: over}
          # Nothing asked for this, so whoever sent it was not answering us.
          in {asked: false}
            false

          # Over Olm, which is what says which device it came from.
          in {over: Events::Decrypted}
            true

          # Nothing was said about how it arrived, so the caller has already judged that.
          in {over: nil}
            true
          else
            false
          end
        end

        # Forget a request, because it was answered or withdrawn.
        #
        # @parameter request_id [String] the ID of the request.
        def cancel(request_id)
          @asked.delete(request_id)
        end

        # A key derived from a passphrase, for a storage this device was told about elsewhere.
        #
        # @parameter passphrase [String] what the user typed.
        # @parameter salt [String] the salt from the description.
        # @parameter iterations [Integer] the rounds from the description.
        # @parameter bits [Integer] how many bits to derive.
        # @returns [SecretStorage::Key] the key.
        def from_passphrase(passphrase, salt:, iterations:, bits: 256)
          SecretStorage::Key.from_passphrase(passphrase, salt: salt, iterations: iterations, bits: bits)
        end

        def inspect
          "\#<#{self.class} #{@held.keys.sort.join(", ")}>"
        end

        private

        # Read everything which was sealed under this storage, now that there is a key for it.
        def read_sealed
          (@sealed || {}).each_key do |name|
            self.load(name)
          end
        end
      end
    end
  end
end
