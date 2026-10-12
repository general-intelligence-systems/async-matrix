#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Replacing an Olm session which has stopped working.
#
# Megolm recovers on its own, because the key for an unreadable message usually arrives later. Olm does not: a session which cannot decrypt is assumed corrupt, and the only way out is a new one.
#
# So a failure is answered with a fresh session and an `m.dummy` over it, and the keys lost with the old one are asked for again. Rate limited to one new session per device per hour, or two confused devices will replace sessions at each other forever.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/unwedging_a_session.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/vodozemac"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

HOUR = 3600

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Vodozemac.new,
  )

  # When each device was last given a replacement session, which is what the rate limit is kept in.
  replaced = {}

  # Open a session with a device and tell it so, which is the whole of the recovery.
  unwedge = lambda do |user_id, sender_key|
    device = machine.devices.by_curve25519(user_id, sender_key)

    case replaced[sender_key]
    # Already done recently, so doing it again would be the loop the specification warns about.
    in Time => at
      Console.warn(self, "Not replacing a session again yet.", user_id: user_id, since: Time.now - at)

      false
    in nil
      machine.accept_claimed_keys(client.keys.claim_keys(machine.without_sessions([device], force: true)))

      # An `m.dummy` carries nothing: it exists so that the pre-key message adopting the session has something to be.
      client.to_device.send_to_device("m.room.encrypted", {
        user_id => {device.device_id => machine.encrypt_to_device(device, "m.dummy", {})},
      })

      replaced[sender_key] = Time.now

      Console.info(self, "Replaced an Olm session.", user_id: user_id, device_id: device.device_id)

      true
    end
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # An Olm message we could not read. The session is assumed corrupt rather than the message bad.
      in {sender:, content: Async::Matrix::Events::Undecryptable(algorithm: "m.olm.v1.curve25519-aes-sha2", sender_key:)}
        Console.error(self, "An Olm message could not be read.", sender: sender)

        if unwedge.call(sender, sender_key)
          # The sessions which were shared over the old channel were lost with it, so they are asked for again.
          machine.store.sessions_from(sender).each do |room_id, session_id|
            machine.request_keys(room_id, session_id: session_id).each do |type, messages|
              client.to_device.send_to_device(type, messages)
            end
          end
        end

      # The other side reached the same conclusion first, and is telling us about its new session.
      in {sender:, content: Async::Matrix::Events::Dummy}
        Console.info(self, "A device replaced its session with us.", sender: sender)

      # It could not even open a session to tell us properly, so we open one towards it.
      in {sender:, content: Async::Matrix::Events::Withheld(code: "m.no_olm", sender_key:)}
        unwedge.call(sender, sender_key)

      # A Megolm failure is not this problem: that key may still arrive, so it waits instead.
      in {room_id:, session_id:, content: Async::Matrix::Events::Deferred}
        Console.debug(self, "Waiting for a room key, which is not a wedged session.", room_id: room_id, session_id: session_id)

      else
        nil
      end
    end
  end
end
