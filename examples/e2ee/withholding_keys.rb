#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Being told that a key is deliberately not coming, and why.
#
# A sender may report that it withheld a session, so the receiving device can say why it cannot read a message rather than showing a generic failure.
#
# Each code means something different about whether the wait can ever end, and `m.no_olm` is the odd one: it names no room and no session, and explains every message that device sent before it.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/withholding_keys.rb

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

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # No Olm session could be established at all, so this one report covers every message that device sent.
      #
      # It names no session, and the answer is a session of our own with an `m.dummy` over it to say so.
      in {sender:, content: Async::Matrix::Events::Withheld(code: "m.no_olm", sender_key:)}
        Console.warn(self, "A device could not reach us at all.", sender: sender)

        device = machine.devices.by_curve25519(sender, sender_key)

        machine.accept_claimed_keys(client.keys.claim_keys(machine.without_sessions([device])))
        client.to_device.send_to_device("m.room.encrypted", {
          sender => {device.device_id => machine.encrypt_to_device(device, "m.dummy", {})},
        })

      # We are not verified yet, so this one ends the moment we are.
      in {sender:, content: Async::Matrix::Events::Withheld(room_id:, session_id:, code: "m.unverified")}
        Console.warn(self, "A device wants us verified first.", sender: sender, room_id: room_id)

        machine.store.refuse(room_id, session_id: session_id, code: "m.unverified", recoverable: true)

      # Deliberately refused, and verifying will not change it.
      in {sender:, content: Async::Matrix::Events::Withheld(room_id:, session_id:, code: "m.blacklisted")}
        Console.warn(self, "A device has blacklisted us.", sender: sender, room_id: room_id)

        machine.store.refuse(room_id, session_id: session_id, code: "m.blacklisted")

      # We were not in the room when the message was sent, so there is nothing to be done about it.
      in {sender:, content: Async::Matrix::Events::Withheld(room_id:, session_id:, code: "m.unauthorised")}
        Console.info(self, "We were not in the room at the time.", sender: sender, room_id: room_id)

        machine.store.refuse(room_id, session_id: session_id, code: "m.unauthorised")

      # The device we asked does not hold it either, so another of that user's devices might.
      in {sender:, content: Async::Matrix::Events::Withheld(room_id:, session_id:, code: "m.unavailable")}
        Console.info(self, "That device does not hold the key either.", sender: sender, room_id: room_id)

        machine.request_keys(room_id, session_id: session_id, except: sender).each do |type, messages|
          client.to_device.send_to_device(type, messages)
        end

      # Only ever seen inside a key bundle: the session was not marked shareable by whoever created it.
      in {sender:, content: Async::Matrix::Events::Withheld(room_id:, session_id:, code: "m.history_not_shared")}
        Console.info(self, "History was not shared for this session.", sender: sender, room_id: room_id)

        machine.store.refuse(room_id, session_id: session_id, code: "m.history_not_shared")

      # A code this version does not define, which is reported rather than guessed at.
      in {sender:, content: Async::Matrix::Events::Withheld(code:, reason:)}
        Console.warn(self, "A session was withheld for a reason we do not know.", sender: sender, code: code, reason: reason)

      # The message this explains, which can now say why rather than simply failing.
      in {room_id:, session_id:, content: Async::Matrix::Events::Withheld}
        Console.info(self, "A message cannot be read, and we know why.", room_id: room_id, session_id: session_id)

      else
        nil
      end
    end
  end
end
