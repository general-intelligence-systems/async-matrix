#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Keeping the private keys somewhere a new device can reach them.
#
# Everything cross signing and key backup rely on is a private key, and a device which cannot get at one is a device which cannot sign or read a backup.
#
# There are two ways to hand it over: secret storage, which is the key encrypted into account data under a passphrase the user knows, and secret sharing, which is one of their own verified devices sending it over Olm. A secret which nobody asked for is never taken.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/secret_storage.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../lib/async/matrix/e2ee/olm"

require "console"
require "securerandom"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

PASSPHRASE = ENV.fetch("MATRIX_PASSPHRASE", nil)

WANTED = ["m.cross_signing.self_signing", "m.cross_signing.user_signing", "m.megolm_backup.v1"].freeze

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # Absent account data is an error rather than an empty answer, so "nothing there" arrives this way.
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

  # Which key the account's storage is encrypted with, and therefore which description to read.
  default = stored.call("m.secret_storage.default_key")

  case {default: default, passphrase: PASSPHRASE}
  # A storage key exists and the user gave us the passphrase, so the keys in it can be opened here.
  in {default: {key: String => key_id}, passphrase: String => passphrase}
    description = stored.call("m.secret_storage.key.#{key_id}")

    case description
    # Derived from a passphrase, which is the usual case: the salt and the rounds are in the description.
    in {algorithm: "m.secret_storage.v1.aes-hmac-sha2", passphrase: {algorithm: "m.pbkdf2", salt:, iterations:}, iv:, mac:}
      storage = machine.secrets.from_passphrase(passphrase, salt: salt, iterations: iterations)

      # The description carries a known plaintext, so a wrong passphrase is caught before anything is decrypted with it.
      case storage.correct?(iv: iv, mac: mac)
      in false
        Console.error(self, "That passphrase does not open this storage.")
      in true
        WANTED.each do |name|
          case stored.call(name)
          in {encrypted: Hash => encrypted}
            # A hash pattern is keyed by label, so the copy under this key is read out before it is used.
            case encrypted[key_id.to_sym]
            in Hash => sealed
              machine.secrets.accept(name, storage.decrypt(name, sealed))

              Console.info(self, "Opened a secret from storage.", name: name)
            else
              Console.warn(self, "Storage holds no copy under this key.", name: name)
            end
          else
            Console.warn(self, "Storage holds no copy of this secret.", name: name)
          end
        end
      end

    # Entered as a key rather than derived, which is the other half of the same algorithm.
    in {algorithm: "m.secret_storage.v1.aes-hmac-sha2", iv:, mac:}
      Console.info(self, "This storage wants the key itself rather than a passphrase.", key_id: key_id)

    in {algorithm: String => algorithm}
      Console.error(self, "This storage uses an algorithm we do not implement.", algorithm: algorithm)
    end

  # Storage exists but we were given nothing to open it with, so the siblings are asked instead.
  in {default: {key: String}, passphrase: nil}
    request_id = SecureRandom.uuid

    machine.secrets.asking(request_id, WANTED.first)

    # Only verified devices of our own are asked, since whoever answers is handed a private key.
    client.to_device.send_to_device("m.secret.request", machine.addressed(machine.devices.verified_of(me), {
      action: "request",
      name: WANTED.first,
      request_id: request_id,
      requesting_device_id: machine.device_id,
    }))

    Console.info(self, "Asked our other devices for a secret.", name: WANTED.first)

  # No storage at all, which is the thing to fix: without it, losing every device loses the identity.
  in {default: nil}
    Console.warn(self, "This account has no secret storage. Set one up before it is needed.")
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # A sibling answered. It must be a device we asked, and the session it came over is what proves which.
      in {sender: ^me, content: Async::Matrix::Events::SecretSend(request_id:, secret:)}
        case machine.secrets.asked?(request_id, over: event)
        in true
          name = machine.secrets.requested(request_id)

          machine.secrets.accept(name, secret)

          # The others are told to stop, so the secret is not sent more times than it has to be.
          client.to_device.send_to_device("m.secret.request", machine.addressed(machine.devices.verified_of(me), {
            action: "request_cancellation",
            request_id: request_id,
            requesting_device_id: machine.device_id,
          }))

          Console.info(self, "A secret arrived from one of our devices.", name: name)

        # Unasked for, or over a session which is not the one we asked on. Either way it is not taken.
        in false
          Console.error(self, "Refused a secret we did not ask for.", request_id: request_id)
        end

      # From another user altogether, which is never a secret of ours.
      in {sender:, content: Async::Matrix::Events::SecretSend(request_id:)}
        Console.error(self, "Another user sent us a secret.", sender: sender, request_id: request_id)

      # One of our own devices is asking us for one. Only a verified device of our own is ever answered.
      in {sender: ^me, content: Async::Matrix::Events::SecretRequest(action: "request", name:, request_id:, requesting_device_id:)}
        device = machine.devices.of(me)[requesting_device_id]

        case {verified: machine.devices.verified?(me, requesting_device_id), secret: machine.secrets.held(name)}
        in {verified: true, secret: String => secret}
          asking = device

          client.to_device.send_to_device("m.room.encrypted", {
            me => {requesting_device_id => machine.encrypt_to_device(asking, "m.secret.send", {
              request_id: request_id,
              secret: secret,
            })},
          })

          Console.info(self, "Sent a secret to one of our verified devices.", name: name)

        in {verified: true, secret: nil}
          Console.warn(self, "A device asked for a secret we do not hold.", name: name)
        in {verified: false}
          Console.error(self, "An unverified device asked for a secret.", device_id: requesting_device_id)
        end

      # Another user asking, which is answered by ignoring it.
      in {sender:, content: Async::Matrix::Events::SecretRequest}
        Console.error(self, "Another user asked us for a secret.", sender: sender)

      in {sender: ^me, content: Async::Matrix::Events::SecretRequest(action: "request_cancellation", request_id:)}
        machine.secrets.cancel(request_id)

      else
        nil
      end
    end
  end
end
