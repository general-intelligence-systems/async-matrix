#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Turning a room encrypted, and sending the first message into it.
#
# The session is Megolm and is shared once; the keys which share it travel over Olm, one message per device.
#
# A device which is not cross signed is told why it was left out rather than left guessing, which is what MSC4153 asks for.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/sending_a_message.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

MEGOLM = "m.megolm.v1.aes-sha2"

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  room = client.create_room(name: "Encrypted", preset: "private_chat")

  # Encryption is room state, so this is what makes the room encrypted rather than any client setting.
  room.set_room_state_with_key("m.room.encryption", {
    algorithm: MEGOLM,
    rotation_period_ms: 604_800_000,
    rotation_period_msgs: 100,
  })

  # Whose devices to share with, and what keys those devices published.
  user_ids = room.get_joined_members_by_room.user_ids
  queried = client.keys.query_keys(user_ids.to_h{|user_id| [user_id, []]})

  # Only cross signed devices are given the session, and the rest are told why.
  recipients, refused = machine.recipients(queried).partition(&:cross_signed?)

  # A device we have never spoken to needs a one time key before it can be addressed at all.
  wanted = machine.without_sessions(recipients)

  unless wanted.empty?
    machine.accept_claimed_keys(client.keys.claim_keys(wanted))
  end

  session = machine.session_for(room.id)

  # Whether the session may be passed on to members who join later, which is true only while the history is visible to them.
  history = room.get_room_state_with_key("m.room.history_visibility")

  case history
  in {content: {history_visibility: "shared" | "world_readable"}}
    shared_history = true
  else
    shared_history = false
  end

  room_key = {
    algorithm: MEGOLM,
    room_id: room.id,
    session_id: session[:session_id],
    session_key: session[:session_key],
    shared_history: shared_history,
  }

  # The key travels Olm encrypted, so what is sent is an `m.room.encrypted` rather than an `m.room_key`.
  messages = recipients.group_by(&:user_id).transform_values do |devices|
    devices.to_h{|device| [device.device_id, machine.encrypt_to_device(device, "m.room_key", room_key)]}
  end

  client.to_device.send_to_device("m.room.encrypted", messages)

  unless refused.empty?
    withheld = refused.group_by(&:user_id).transform_values do |devices|
      devices.to_h do |device|
        [device.device_id, {
          algorithm: MEGOLM,
          room_id: room.id,
          session_id: session[:session_id],
          sender_key: machine.crypto.identity_keys[:curve25519],
          code: "m.unverified",
          reason: "This device is not cross signed.",
        }]
      end
    end

    # A withheld report goes in the clear, since the point of it is that there is no session to send it over.
    client.to_device.send_to_device("m.room_key.withheld", withheld)
  end

  Console.info(self, "Shared a session.", room_id: room.id, recipients: recipients.size, refused: refused.size)

  content = machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "Hello, in private."))
  sent = room.send_message(content.type, content.to_h)

  # The event comes back through sync like anybody else's, so this is only the proof it was accepted.
  case machine.wrap(room.get_one_room_event(sent.event_id).value)
  in {content: Async::Matrix::Events::RoomEncrypted(algorithm: MEGOLM, session_id:)}
    Console.info(self, "The homeserver stored ciphertext.", event_id: sent.event_id, session_id: session_id)
  in {content: Async::Matrix::Events::Content => content}
    Console.error(self, "The homeserver stored something readable!", type: content.type)
  end
end
