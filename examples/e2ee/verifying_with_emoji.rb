#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Verifying by comparing seven pictures, which is the deprecated way.
#
# MSC4405 deprecated the emoji method: each client shows the names in its own language, so two users can hold different words for one picture, and 🔧 is a spanner in one English and a wrench in another.
#
# So this flow is here to be read, not offered. A client which meets a device offering nothing else can still complete it, which is why the table is still bound and why the arm below asks for emoji explicitly rather than taking the default.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/verifying_with_emoji.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/olm"

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

  verifications = {}

  send_to = lambda do |user_id, device_id, type, content|
    client.to_device.send_to_device(type, {user_id => {device_id => content}})
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      in {sender:, content: Async::Matrix::Events::KeyVerificationRequest(from_device:, transaction_id:, methods: [*, "m.sas.v1", *])}
        verifications[transaction_id] = machine.verification(sender, from_device, transaction_id)

        send_to.call(sender, from_device, "m.key.verification.ready", {
          from_device: machine.device_id,
          transaction_id: transaction_id,
          methods: ["m.sas.v1"],
        })

      # A device which offers emoji and nothing else. Decimal is required of every client, so this is a client which does not follow the specification.
      in {sender:, content: Async::Matrix::Events::KeyVerificationStartSasV1(from_device:, transaction_id:, short_authentication_string: ["emoji"]) => start}
        verification = verifications[transaction_id] or next

        Console.warn(self, "This device offers only the deprecated method.", sender: sender)

        # Asked for explicitly, because the default offer is decimal alone.
        send_to.call(sender, from_device, "m.key.verification.accept", {
          transaction_id: transaction_id,
          key_agreement_protocol: "curve25519-hkdf-sha256",
          hash: "sha256",
          message_authentication_code: "hkdf-hmac-sha256.v2",
          short_authentication_string: start.agreed(offered: ["emoji"]),
          commitment: verification.commitment(start),
        })

      # A device which offers both takes decimal, and this is the arm which makes that happen.
      in {sender:, content: Async::Matrix::Events::KeyVerificationStartSasV1(from_device:, transaction_id:, short_authentication_string: [*, "decimal", *]) => start}
        verification = verifications[transaction_id] or next

        send_to.call(sender, from_device, "m.key.verification.accept", {
          transaction_id: transaction_id,
          key_agreement_protocol: "curve25519-hkdf-sha256",
          hash: "sha256",
          message_authentication_code: "hkdf-hmac-sha256.v2",
          short_authentication_string: start.agreed,
          commitment: verification.commitment(start),
        })

      in {sender:, content: Async::Matrix::Events::KeyVerificationAccept(transaction_id:, commitment:, short_authentication_string:)}
        verification = verifications[transaction_id] or next
        verification.commited(commitment, methods: short_authentication_string)

        send_to.call(sender, verification.device_id, "m.key.verification.key", {
          transaction_id: transaction_id,
          key: verification.public_key,
        })

      # Both keys are in, so what to show the user depends on which method was agreed.
      in {sender:, content: Async::Matrix::Events::KeyVerificationKey(transaction_id:, key:)}
        verification = verifications[transaction_id] or next
        verification.received(key) or next

        unless verification.sent_key?
          send_to.call(sender, verification.device_id, "m.key.verification.key", {
            transaction_id: transaction_id,
            key: verification.public_key,
          })
        end

        case verification.method
        # Seven indices into the table the specification defines, each with a name which is translated per client.
        in "emoji"
          emoji = verification.emoji

          Console.info(self, "Compare these pictures.", emoji: emoji.map{|index| Async::Matrix::E2EE::EMOJI[index]})
          Console.info(self, "Their names, which the other person may hold in another language.", names: emoji.map{|index| Async::Matrix::E2EE::EMOJI_NAMES[index]})
        in "decimal"
          Console.info(self, "Compare these numbers.", numbers: verification.decimals)
        end

        if machine.confirmed?(verification)
          send_to.call(sender, verification.device_id, "m.key.verification.mac", verification.mac)
        else
          send_to.call(sender, verification.device_id, "m.key.verification.cancel", {
            transaction_id: transaction_id,
            code: "m.mismatched_sas",
            reason: "They did not match.",
          })
        end

      in {sender:, content: Async::Matrix::Events::KeyVerificationMac(transaction_id:, mac:, keys:)}
        verification = verifications[transaction_id] or next

        case verification.verify(mac: mac, keys: keys)
        in {verified: [_, *] => verified}
          send_to.call(sender, verification.device_id, "m.key.verification.done", {transaction_id: transaction_id})

          Console.info(self, "Verified, the old way.", sender: sender, keys: verified)
        else
          send_to.call(sender, verification.device_id, "m.key.verification.cancel", {
            transaction_id: transaction_id,
            code: "m.key_mismatch",
            reason: "No key matched its own code.",
          })
        end

      # An alternative pattern may not capture, so the field is read from the content it binds instead.
      in {content: Async::Matrix::Events::KeyVerificationDone | Async::Matrix::Events::KeyVerificationCancel => content}
        verifications.delete(content[:transaction_id])

      else
        nil
      end
    end
  end
end
