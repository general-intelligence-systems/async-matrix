#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Verifying by scanning a code, which takes one scan rather than a comparison.
#
# The code carries both master keys and a shared secret, so scanning it proves two things at once: the scanner learns the other key, and the scanned side learns that the scanner had the right key for it.
#
# Which is why the scanner then sends `m.reciprocate.v1` carrying that secret: it is not a verification step, only the signal that the scan happened, so the other side can ask its user to confirm.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/verifying_with_qr_code.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

# What each mode of the code means, which decides what its two keys are.
VERIFYING_USER = 0x00
SELF_TRUSTED = 0x01
SELF_UNTRUSTED = 0x02

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  verifications = {}

  send_to = lambda do |user_id, device_id, type, content|
    client.to_device.send_to_device(type, {user_id => {device_id => content}})
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # Both sides may show and scan, so the methods they list decide which way round this goes.
      in {sender:, content: Async::Matrix::Events::KeyVerificationRequest(from_device:, transaction_id:, methods: [*, "m.reciprocate.v1", *] => methods)}
        verification = machine.verification(sender, from_device, transaction_id)
        verifications[transaction_id] = verification

        ours = ["m.reciprocate.v1"]

        # Showing is for them to scan; scanning is for us to read theirs.
        case methods
        in [*, "m.qr_code.scan.v1", *]
          ours << "m.qr_code.show.v1"
        else
          nil
        end

        case methods
        in [*, "m.qr_code.show.v1", *]
          ours << "m.qr_code.scan.v1"
        else
          nil
        end

        send_to.call(sender, from_device, "m.key.verification.ready", {
          from_device: machine.device_id,
          transaction_id: transaction_id,
          methods: ours,
        })

        # What we display, for them to scan. The mode decides which keys go in it.
        if ours.include?("m.qr_code.show.v1")
          Console.info(self, "Show this code.", code: verification.qr_code(mode: VERIFYING_USER))
        end

      # Our user scanned theirs. The bytes say who it claims to be, and the keys must be the ones we already hold.
      in {sender:, content: Async::Matrix::Events::KeyVerificationReady(from_device:, transaction_id:)}
        verification = verifications[transaction_id] or next

        # Each mode names its two keys differently, so what to check depends on which it is.
        case machine.scanned(transaction_id)
        # Nothing was scanned on this device, so there is nothing to reciprocate.
        in nil
          checked = nil

        # Verifying another user: the first key is their master key, the second is what they think ours is.
        in {mode: VERIFYING_USER, transaction_id: ^transaction_id, first:, second:, secret:}
          checked = {matches: verification.expects?(theirs: first, ours: second), secret: secret, keys: [first], mode: VERIFYING_USER}

        # Verifying ourselves, from a device which already trusts the master key.
        in {mode: SELF_TRUSTED, first:, second:, secret:}
          checked = {matches: verification.expects?(theirs: second, ours: first), secret: secret, keys: [second], mode: SELF_TRUSTED}

        # Verifying ourselves from a device which does not trust it yet, so the keys are the other way round.
        in {mode: SELF_UNTRUSTED, first:, second:, secret:}
          checked = {matches: verification.expects?(master: second, device: first), secret: secret, keys: [second], mode: SELF_UNTRUSTED}
        end

        case checked
        in nil
          nil

        # The scan proved their key, so what remains is telling them it succeeded.
        in {matches: true, secret:, keys: Array => keys}
          machine.sign_verified(keys).each do |signatures|
            client.cross_signing.upload_cross_signing_signatures(signatures)
          end

          send_to.call(sender, from_device, "m.key.verification.start", {
            from_device: machine.device_id,
            transaction_id: transaction_id,
            method: "m.reciprocate.v1",
            secret: secret,
          })

          Console.info(self, "The code matched, so they are verified.", sender: sender)

        # The code did not carry the keys we hold, which is what an attempt looks like.
        in {matches: false, mode:}
          send_to.call(sender, from_device, "m.key.verification.cancel", {
            transaction_id: transaction_id,
            code: "m.key_mismatch",
            reason: "The code did not carry the keys we hold for this device.",
          })

          Console.error(self, "A scanned code carried the wrong keys.", sender: sender, mode: mode)
        end

      # They scanned ours and are telling us so. The secret proves it was our code they read.
      in {sender:, content: Async::Matrix::Events::KeyVerificationStartReciprocateV1(from_device:, transaction_id:, secret:)}
        verification = verifications[transaction_id] or next

        case verification.secret?(secret)
        in false
          Console.error(self, "Somebody claimed to scan a code they never saw.", sender: sender)

          send_to.call(sender, from_device, "m.key.verification.cancel", {
            transaction_id: transaction_id,
            code: "m.mismatched_sas",
            reason: "The shared secret does not match.",
          })
        in true
          # They can only have confirmed if our key was right in their code, so their word is the whole proof.
          if machine.confirmed?(verification)
            machine.sign_verified(verification.their_keys).each do |signatures|
              client.cross_signing.upload_cross_signing_signatures(signatures)
            end

            send_to.call(sender, from_device, "m.key.verification.done", {transaction_id: transaction_id})
          else
            send_to.call(sender, from_device, "m.key.verification.cancel", {
              transaction_id: transaction_id,
              code: "m.user",
              reason: "Our user did not confirm the scan.",
            })
          end
        end

      in {content: Async::Matrix::Events::KeyVerificationDone | Async::Matrix::Events::KeyVerificationCancel => content}
        verifications.delete(content[:transaction_id])

      else
        nil
      end
    end
  end
end
