#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Putting a private key into account data, and reading one back out.
#
# A secret is encrypted under the storage key and filed in the account data event named after it, so the server holds the cross signing keys and the backup key without being able to read any of them.
#
# The name matters: it is the info parameter of the derivation, so the same storage key encrypts each secret with a different AES key. A ciphertext filed under the wrong name will not open.
#
# One secret may be encrypted under several keys at once, which is what `encrypted` being a map is for, and a client reads whichever of them it holds.
#
#   MATRIX_PASSPHRASE=correct-horse ruby examples/e2ee/storing_a_secret.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

PASSPHRASE = ENV.fetch("MATRIX_PASSPHRASE", "correct-horse")

# What goes in here, each base64 encoded before it is encrypted.
SECRETS = [
  "m.cross_signing.master",
  "m.cross_signing.self_signing",
  "m.cross_signing.user_signing",
  "m.megolm_backup.v1",
].freeze

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # Absent account data is an error rather than an empty answer, so this is how "nothing there" is read.
  stored = lambda do |type|
    begin
      client.account_data.get_account_data(me, type)
    rescue Async::Matrix::RequestError => error
      case error.errcode
      in "M_NOT_FOUND"
        nil
      end
    end
  end

  case stored.call("m.secret_storage.default_key")
  # No storage, so there is nowhere to put a secret: examples/e2ee/storage_key.rb is what makes one.
  in nil
    Console.warn(self, "This account has no secret storage yet.")

  in {key: String => key_id}
    description = stored.call("m.secret_storage.key.#{key_id}")

    case description
    in {passphrase: {algorithm: "m.pbkdf2", salt:, iterations:, **rest}}
      key = Async::Matrix::E2EE::SecretStorage::Key.from_passphrase(PASSPHRASE, salt: salt, iterations: iterations, bits: rest.fetch(:bits, 256))

      # Whether the passphrase is right is asked before anything is written under it, or the secrets become unreadable.
      case description
      in {iv: String => iv, mac: String => mac}
        unless key.correct?(iv: iv, mac: mac)
          Console.error(self, "That passphrase does not open this storage.")

          next
        end
      else
        nil
      end

      storage = Async::Matrix::E2EE::SecretStorage.new(key_id => key)

      SECRETS.each do |name|
        case stored.call(name)
        # Already there, and ours to read if one of the keys it was encrypted under is one we hold.
        in {encrypted: Hash => encrypted}
          case storage.decrypt(name, encrypted)
          in String => secret
            Console.info(self, "Read a secret.", name: name, bytes: secret.bytesize)

          # Encrypted under keys we do not hold, which is what another client's key looks like.
          in nil
            Console.warn(self, "This secret is not encrypted under any key we hold.", name: name, keys: encrypted.keys)
          end

        # Not there, so this is where a client which just made these keys would put them.
        in nil
          secret = machine.crypto.identity_keys[:ed25519]

          # Filed beside whatever other keys it is already encrypted under, rather than replacing them.
          client.account_data.set_account_data(me, name, {encrypted: storage.encrypt(name, secret)})

          Console.info(self, "Stored a secret.", name: name)
        end
      end

      # The name is the info parameter of the derivation, so the same ciphertext under another name does not open.
      case stored.call(SECRETS.first)
      in {encrypted: Hash => encrypted}
        expect = storage.decrypt(SECRETS.last, encrypted)

        case expect
        in nil
          Console.info(self, "A secret does not open under another secret's name, as it should not.")
        in String
          Console.error(self, "A secret opened under the wrong name, so the name is not reaching the derivation.")
        end
      else
        nil
      end

    in {algorithm: "m.secret_storage.v1.aes-hmac-sha2"}
      Console.error(self, "This storage wants the key itself rather than a passphrase.", key_id: key_id)

    in nil
      Console.error(self, "The default key names a description which is not there.", key_id: key_id)
    end
  end
end
