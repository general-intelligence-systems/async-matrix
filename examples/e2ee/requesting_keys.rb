#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Asking another device for a session, and answering when asked.
#
# A device which is missing a key can ask for it, and a device which holds it may forward it. The forward is ratcheted to the index asked for, so it unlocks the messages from there on and nothing earlier.
#
# Key sharing is an attack surface, so the rule is narrow: only answer the verified devices of the same user, and only accept a forward from one. A request which is answered is cancelled to the devices still holding it.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/requesting_keys.rb

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

  # The requests we made, so that an answer can be matched to one and the rest cancelled.
  outstanding = {}

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # A session we do not hold, so every other device of ours is asked for it.
      in {room_id:, session_id:, content: Async::Matrix::Events::Deferred}
        case outstanding.key?(session_id)
        # Already asked, and asking again would only repeat ourselves at every batch.
        in true
          nil
        in false
          request_id = SecureRandom.uuid
          outstanding[session_id] = {request_id: request_id, room_id: room_id}

          client.to_device.send_to_device("m.room_key_request", machine.addressed(machine.devices.of(me), {
            action: "request",
            request_id: request_id,
            requesting_device_id: machine.device_id,
            body: {algorithm: "m.megolm.v1.aes-sha2", room_id: room_id, session_id: session_id},
          }))

          Console.info(self, "Asked our other devices for a session.", room_id: room_id, session_id: session_id)
        end

      # Another of our own devices is asking us. Only a verified one is answered, and only for a session we hold.
      in {sender: ^me, content: Async::Matrix::Events::RoomKeyRequest(action: "request", request_id:, requesting_device_id:, body: {room_id:, session_id:})}
        device = machine.devices.of(me)[requesting_device_id]

        case machine.devices.verified?(me, requesting_device_id)
        # Unverified, so it is told why rather than left waiting.
        in false
          client.to_device.send_to_device("m.room_key.withheld", {
            me => {requesting_device_id => {
              algorithm: "m.megolm.v1.aes-sha2",
              room_id: room_id,
              session_id: session_id,
              sender_key: machine.crypto.identity_keys[:curve25519],
              code: "m.unverified",
              reason: "Verify this device first.",
            }},
          })

        in true
          asking = machine.devices.of(me)[requesting_device_id]

          # Exported from the earliest index we can reach, so it reads as much as we can give it.
          case machine.forwardable(room_id, session_id: session_id, to: asking)
          in {content: Hash => forwarded}
            client.to_device.send_to_device("m.room.encrypted", {
              me => {requesting_device_id => machine.encrypt_to_device(asking, "m.forwarded_room_key", forwarded)},
            })

            Console.info(self, "Forwarded a session to our own device.", device_id: requesting_device_id)

          # We do not hold it either, which is its own answer.
          in nil
            client.to_device.send_to_device("m.room_key.withheld", {
              me => {requesting_device_id => {
                algorithm: "m.megolm.v1.aes-sha2",
                room_id: room_id,
                session_id: session_id,
                sender_key: machine.crypto.identity_keys[:curve25519],
                code: "m.unavailable",
                reason: "This device does not hold that session.",
              }},
            })
          end
        end

      # Another user asking, which is never answered: sessions go to our own devices alone.
      in {sender:, content: Async::Matrix::Events::RoomKeyRequest(action: "request")}
        Console.warn(self, "Ignoring a key request from another user.", sender: sender)

      # They found it elsewhere, so any pending answer of ours is dropped.
      in {sender:, content: Async::Matrix::Events::RoomKeyRequest(action: "request_cancellation", request_id:, requesting_device_id:)}
        machine.store.cancel(request_id)

        Console.debug(self, "A request was withdrawn.", sender: sender, device_id: requesting_device_id)

      # The answer. It carries the chain it travelled, and is trusted no further than the device which sent it.
      in {sender: ^me, content: Async::Matrix::Events::ForwardedRoomKey(room_id:, session_id:, forwarding_curve25519_key_chain:, withheld:)}
        Console.info(self, "A session was forwarded to us.", room_id: room_id, hops: forwarding_curve25519_key_chain.size, withheld: withheld)

        # Asked of several devices, so the others are told to stop looking.
        case outstanding.delete(session_id)
        in {request_id:}
          client.to_device.send_to_device("m.room_key_request", machine.addressed(machine.devices.of(me), {
            action: "request_cancellation",
            request_id: request_id,
            requesting_device_id: machine.device_id,
          }))
        else
          nil
        end

      # A forward from somebody else's device, which proves nothing about who created the session.
      in {sender:, content: Async::Matrix::Events::ForwardedRoomKey}
        Console.error(self, "Refused a forwarded session from another user.", sender: sender)

      else
        nil
      end
    end
  end
end
