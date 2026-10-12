#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Verifying another user through the room we share with them.
#
# Two users verify in a direct message rather than device to device, because neither knows which of the other's devices to address.
#
# So the request is a message in the room, and its event ID is the transaction: every later event points back at it with `m.relates_to`. One request is sent rather than one per device, and a device which sees another answer knows to stop offering.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/verifying_in_a_room.rb

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
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # Keyed by the event ID of the request, which is what an in-room verification is identified by.
  verifications = {}

  # Each step is a room event, and the relation is what ties it to the request.
  send_step = lambda do |room_id, event_id, type, content|
    client.room(room_id).send_message(type, content.merge(
      "m.relates_to": {rel_type: "m.reference", event_id: event_id},
    ))
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # A request is an ordinary message, so a client which does not verify shows it as text and nothing breaks.
      in {room_id:, event_id:, sender:, content: Async::Matrix::Events::KeyVerificationRequestMessage(from_device:, methods: [*, "m.sas.v1", *], to: ^me)}
        verifications[event_id] = machine.verification(sender, from_device, event_id)

        # The ready goes to the room too, which is how the sender's other devices learn it was answered.
        send_step.call(room_id, event_id, "m.key.verification.ready", {
          from_device: machine.device_id,
          methods: ["m.sas.v1"],
        })

        Console.info(self, "Accepted a verification in a room.", room_id: room_id, sender: sender)

      # Addressed to somebody else in the same room, which is not ours to answer.
      in {sender:, content: Async::Matrix::Events::KeyVerificationRequestMessage(to:)}
        Console.debug(self, "A verification between other people.", sender: sender, to: to)

      # Our own request, answered on another of our devices: no cancel is sent in a room, the ready is the signal.
      in {sender: ^me, content: Async::Matrix::Events::KeyVerificationReady(from_device:)}
        case from_device == machine.device_id
        in false
          Console.info(self, "Another of our devices took this verification.", device_id: from_device)
        in true
          nil
        end

      # From here the steps are the same as the device to device flow, only carried as room events.
      in {room_id:, sender:, content: Async::Matrix::Events::KeyVerificationStartSasV1 => start}
        verification = verifications[start.related_to] or next

        send_step.call(room_id, start.related_to, "m.key.verification.accept", {
          key_agreement_protocol: "curve25519-hkdf-sha256",
          hash: "sha256",
          message_authentication_code: "hkdf-hmac-sha256.v2",
          short_authentication_string: start.agreed,
          commitment: verification.commitment(start),
        })

      in {room_id:, content: Async::Matrix::Events::KeyVerificationAccept(commitment:, short_authentication_string:) => accept}
        verification = verifications[accept.related_to] or next
        verification.commited(commitment, methods: short_authentication_string)

        send_step.call(room_id, accept.related_to, "m.key.verification.key", {key: verification.public_key})

      in {room_id:, content: Async::Matrix::Events::KeyVerificationKey(key:) => received}
        verification = verifications[received.related_to] or next
        verification.received(key) or next

        unless verification.sent_key?
          send_step.call(room_id, received.related_to, "m.key.verification.key", {key: verification.public_key})
        end

        Console.info(self, "Read these to the other person.", numbers: verification.decimals)

        if machine.confirmed?(verification)
          send_step.call(room_id, received.related_to, "m.key.verification.mac", verification.mac)
        else
          send_step.call(room_id, received.related_to, "m.key.verification.cancel", {
            code: "m.mismatched_sas",
            reason: "The numbers did not match.",
          })
        end

      in {room_id:, sender:, content: Async::Matrix::Events::KeyVerificationMac(mac:, keys:) => macs}
        verification = verifications[macs.related_to] or next

        case verification.verify(mac: mac, keys: keys)
        in {verified: [_, *] => verified}
          # Between two users it is the master key which is signed, so one verification covers all their devices.
          machine.sign_verified(verified).each do |signatures|
            client.cross_signing.upload_cross_signing_signatures(signatures)
          end

          send_step.call(room_id, macs.related_to, "m.key.verification.done", {})

          Console.info(self, "Verified another user.", sender: sender, keys: verified)
        else
          send_step.call(room_id, macs.related_to, "m.key.verification.cancel", {
            code: "m.key_mismatch",
            reason: "No key matched its own code.",
          })
        end

      in {content: Async::Matrix::Events::KeyVerificationDone | Async::Matrix::Events::KeyVerificationCancel => content}
        verifications.delete(content.related_to)

      else
        nil
      end
    end
  end
end
