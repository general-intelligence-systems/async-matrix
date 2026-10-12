#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Verifying another device by reading three numbers aloud.
#
# This is the short authentication string, and it is the flow to offer: decimal is required of every client, and MSC4405 deprecated the alternative.
#
# The handshake is a sequence, so each event is the cue for the next: request, ready, start, accept, key, key, mac, mac, done. The numbers appear once both keys are in, and the user answers the one question the protocol cannot.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/verifying_with_decimal.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # One verification per transaction, each holding its own ephemeral key and what it has been told.
  verifications = {}

  send_to = lambda do |user_id, device_id, type, content|
    client.to_device.send_to_device(type, {user_id => {device_id => content}})
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # Somebody wants to verify. The methods they list are what they can do; we answer with what we will do.
      in {sender:, content: Async::Matrix::Events::KeyVerificationRequest(from_device:, transaction_id:, methods: [*, "m.sas.v1", *])}
        verifications[transaction_id] = machine.verification(sender, from_device, transaction_id)

        send_to.call(sender, from_device, "m.key.verification.ready", {
          from_device: machine.device_id,
          transaction_id: transaction_id,
          methods: ["m.sas.v1"],
        })

        Console.info(self, "Accepted a verification request.", sender: sender, transaction_id: transaction_id)

      # They offered no method we know, which is not ours to cancel: another of their devices may answer.
      in {sender:, content: Async::Matrix::Events::KeyVerificationRequest(transaction_id:, methods:)}
        Console.warn(self, "No method in common.", sender: sender, methods: methods, transaction_id: transaction_id)

      # They chose SAS. The accept names the one algorithm of each kind we will use, and commits to our key before seeing theirs.
      in {sender:, content: Async::Matrix::Events::KeyVerificationStartSasV1(from_device:, transaction_id:, key_agreement_protocols: [*, "curve25519-hkdf-sha256", *], message_authentication_codes: [*, "hkdf-hmac-sha256.v2", *]) => start}
        verification = verifications[transaction_id] or next

        # Decimal alone: offering emoji is deprecated, and decimal always agrees.
        agreed = start.agreed

        case agreed
        in []
          send_to.call(sender, from_device, "m.key.verification.cancel", {
            transaction_id: transaction_id,
            code: "m.unknown_method",
            reason: "Only the decimal short authentication string is offered.",
          })
        in [*]
          send_to.call(sender, from_device, "m.key.verification.accept", {
            transaction_id: transaction_id,
            key_agreement_protocol: "curve25519-hkdf-sha256",
            hash: "sha256",
            message_authentication_code: "hkdf-hmac-sha256.v2",
            short_authentication_string: agreed,
            # The commitment is over our key and their start, so neither side can choose its key after seeing the other's.
            commitment: verification.commitment(start),
          })
        end

      # They accepted ours, so the exchange begins: our key first, since we started.
      in {sender:, content: Async::Matrix::Events::KeyVerificationAccept(transaction_id:, commitment:, short_authentication_string:)}
        verification = verifications[transaction_id] or next
        verification.commited(commitment, methods: short_authentication_string)

        send_to.call(sender, verification.device_id, "m.key.verification.key", {
          transaction_id: transaction_id,
          key: verification.public_key,
        })

      # Their key. Once both are in, the numbers can be derived and the commitment checked.
      in {sender:, content: Async::Matrix::Events::KeyVerificationKey(transaction_id:, key:)}
        verification = verifications[transaction_id] or next

        case verification.received(key)
        # The hash they committed to does not match the key they sent, which is the attack this guards against.
        in false
          send_to.call(sender, verification.device_id, "m.key.verification.cancel", {
            transaction_id: transaction_id,
            code: "m.mismatched_commitment",
            reason: "The committed hash does not match the key.",
          })
        in true
          # If they sent first, ours still has to go.
          unless verification.sent_key?
            send_to.call(sender, verification.device_id, "m.key.verification.key", {
              transaction_id: transaction_id,
              key: verification.public_key,
            })
          end

          first, second, third = verification.decimals

          Console.info(self, "Read these to the other person.", numbers: [first, second, third])

          # The one thing no protocol can decide. A real client asks, and cancels with `m.mismatched_sas` on a no.
          if machine.confirmed?(verification)
            send_to.call(sender, verification.device_id, "m.key.verification.mac", verification.mac)
          else
            send_to.call(sender, verification.device_id, "m.key.verification.cancel", {
              transaction_id: transaction_id,
              code: "m.mismatched_sas",
              reason: "The numbers did not match.",
            })
          end
        end

      # Their MACs over the keys they want verified, which must agree with the keys we hold for them.
      in {sender:, content: Async::Matrix::Events::KeyVerificationMac(transaction_id:, mac:, keys:)}
        verification = verifications[transaction_id] or next

        case verification.verify(mac: mac, keys: keys)
        in {verified: [], unverified: Array}
          send_to.call(sender, verification.device_id, "m.key.verification.cancel", {
            transaction_id: transaction_id,
            code: "m.key_mismatch",
            reason: "No key matched its own code.",
          })
        in {verified: Array => verified}
          # Signing their master key with ours is what makes the verification worth having beyond this one device.
          machine.sign_verified(verified).each do |signatures|
            client.cross_signing.upload_cross_signing_signatures(signatures)
          end

          send_to.call(sender, verification.device_id, "m.key.verification.done", {transaction_id: transaction_id})

          Console.info(self, "Verified.", sender: sender, keys: verified)
        end

      # Both sides say so, and the transaction is finished with.
      in {sender:, content: Async::Matrix::Events::KeyVerificationDone(transaction_id:)}
        verifications.delete(transaction_id)

        Console.info(self, "The other device agrees it is done.", sender: sender)

      # Either side may give up at any point, and the code says what went wrong.
      in {sender:, content: Async::Matrix::Events::KeyVerificationCancel(transaction_id:, code:, reason:)}
        verifications.delete(transaction_id)

        Console.warn(self, "The verification was cancelled.", sender: sender, code: code, reason: reason)

      else
        nil
      end
    end

    # A prompt which nobody answers is dismissed, and a transaction which goes unused is forgotten.
    verifications.delete_if do |transaction_id, verification|
      verification.expired?.tap do |expired|
        if expired
          Console.info(self, "A verification timed out.", transaction_id: transaction_id)
        end
      end
    end
  end
end
