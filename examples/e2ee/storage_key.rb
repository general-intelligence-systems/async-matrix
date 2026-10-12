#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Making the key which secret storage is encrypted under, and checking one a user gave us.
#
# There are two ways to come by it: generated at random, which is then shown to the user to write down, or derived from a passphrase they chose, which is PBKDF2 with SHA-512 over a salt and iteration count kept in the key's description.
#
# Either way the description carries a check: the key encrypts 32 bytes of zero, and the MAC of that is stored. So a client can tell a wrong passphrase from a right one before it decrypts anything with it, which is the difference between "that is not your passphrase" and a pile of rubbish.
#
# Those two properties are optional, and where they are absent the key MUST be assumed valid.
#
#   MATRIX_PASSPHRASE=correct-horse ruby examples/e2ee/storage_key.rb
#
#   MATRIX_KEY='EsTc LW2K PGiF wKEA 3As5 g5c4 BXwk qeeJ ZJV8 Q9fu gUMN UE4d'

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/olm"

require "console"
require "securerandom"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

PASSPHRASE = ENV.fetch("MATRIX_PASSPHRASE", nil)
TYPED = ENV.fetch("MATRIX_KEY", nil)

# The specification's own example, and what a client should not go below.
ITERATIONS = 500_000

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # Which key the account's storage is already encrypted under, if it has one at all.
  existing = begin
    client.account_data.get_account_data(me, "m.secret_storage.default_key")
  rescue Async::Matrix::RequestError => error
    # Absent account data is an error rather than an empty answer, so "no storage yet" arrives this way.
    case error.errcode
    in "M_NOT_FOUND"
      nil
    end
  end

  case {existing: existing, passphrase: PASSPHRASE, typed: TYPED}
  # A key the user typed back in, which is the one case where the representation in the appendices is read rather than written.
  in {existing: {key: String => key_id}, typed: String => typed}
    description = client.account_data.get_account_data(me, "m.secret_storage.key.#{key_id}")

    case Async::Matrix::KeyRepresentation.decode(typed)
    # The parity byte and the header are what catch a typo before anything is decrypted with it.
    in nil
      Console.error(self, "That is not a key: the header or the parity byte is wrong.")

    in String => bytes
      key = Async::Matrix::E2EE::SecretStorage::Key.from_bytes(bytes)

      case description
      # The check values are optional, and a key MUST be assumed valid where they are absent.
      in {iv: String => iv, mac: String => mac}
        case key.correct?(iv: iv, mac: mac)
        in true
          Console.info(self, "That is the key.", key_id: key_id)
        in false
          Console.error(self, "That key does not open this storage.", key_id: key_id)
        end
      else
        Console.warn(self, "This description carries no check, so the key is taken on trust.", key_id: key_id)
      end
    end

  # A passphrase, against storage which already exists: the salt and the count come from the description rather than from us.
  in {existing: {key: String => key_id}, passphrase: String => passphrase}
    description = client.account_data.get_account_data(me, "m.secret_storage.key.#{key_id}")

    case description
    in {algorithm: "m.secret_storage.v1.aes-hmac-sha2", passphrase: {algorithm: "m.pbkdf2", salt:, iterations:, **rest}, iv:, mac:}
      # The number of bits is optional and means 256 where it is absent.
      bits = rest.fetch(:bits, 256)

      key = Async::Matrix::E2EE::SecretStorage::Key.from_passphrase(passphrase, salt: salt, iterations: iterations, bits: bits)

      case key.correct?(iv: iv, mac: mac)
      in true
        Console.info(self, "That is the passphrase.", key_id: key_id, iterations: iterations)
      in false
        Console.error(self, "That passphrase does not open this storage.", key_id: key_id)
      end

    # Derived some other way, or not derived at all, so a passphrase is not what it wants.
    in {algorithm: "m.secret_storage.v1.aes-hmac-sha2"}
      Console.error(self, "This storage wants the key itself rather than a passphrase.", key_id: key_id)

    in {algorithm: String => algorithm}
      Console.error(self, "This storage uses an algorithm we do not implement.", algorithm: algorithm)
    end

  # No storage, and a passphrase to make one from.
  in {existing: nil, passphrase: String => passphrase}
    salt = SecureRandom.base64(32)
    key = Async::Matrix::E2EE::SecretStorage::Key.from_passphrase(passphrase, salt: salt, iterations: ITERATIONS)

    key_id = SecureRandom.alphanumeric(24)

    client.account_data.set_account_data(me, "m.secret_storage.key.#{key_id}", key.description(
      name: "Passphrase",
      passphrase: {algorithm: "m.pbkdf2", salt: salt, iterations: ITERATIONS, bits: 256},
    ))

    # A client which makes a key marks it as the default, or a simpler client will behave as though there were none.
    client.account_data.set_account_data(me, "m.secret_storage.default_key", {key: key_id})

    Console.info(self, "Made storage from a passphrase.", key_id: key_id)

  # No storage and no passphrase, so the key is random and the user has to keep it.
  in {existing: nil}
    key = Async::Matrix::E2EE::SecretStorage::Key.generate
    key_id = SecureRandom.alphanumeric(24)

    client.account_data.set_account_data(me, "m.secret_storage.key.#{key_id}", key.description(name: "Default key"))
    client.account_data.set_account_data(me, "m.secret_storage.default_key", {key: key_id})

    # The one place a private key is shown to a person, so it is shown the way the appendices say.
    Console.info(self, "Write this down. It is the only copy.", key: Async::Matrix::KeyRepresentation.encode(key.bytes))

  # Storage exists and we were given nothing to open it with.
  in {existing: {key: String => key_id}}
    Console.warn(self, "This account has storage, but no passphrase or key was given.", key_id: key_id)
  end
end
