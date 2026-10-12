#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Replacing the session a room is encrypted with, before it should not be used again.
#
# A session must be rotated when its time or message count runs out, when anybody leaves the room, and when the history visibility changes in a way which would change whether the session may be passed on.
#
# Since v1.19 a departing invitee counts too, because a key bundle may already have given them the keys. In a limited sync any membership which is not `join` is treated as somebody who may have joined and left while we were not looking.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/rotating_a_session.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

SHAREABLE = ["shared", "world_readable"].freeze

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # Begin a session and give it to everybody who should hold it, which is the whole of a rotation.
  share = lambda do |room_id, because:|
    room = client.room(room_id)
    user_ids = room.get_joined_members_by_room.user_ids
    queried = client.keys.query_keys(user_ids.to_h{|user_id| [user_id, []]})

    recipients = machine.recipients(queried).select(&:cross_signed?)
    wanted = machine.without_sessions(recipients)

    unless wanted.empty?
      machine.accept_claimed_keys(client.keys.claim_keys(wanted))
    end

    session = machine.session_for(room_id, rotate: true)

    messages = recipients.group_by(&:user_id).transform_values do |devices|
      devices.to_h do |device|
        [device.device_id, machine.encrypt_to_device(device, "m.room_key", {
          algorithm: "m.megolm.v1.aes-sha2",
          room_id: room_id,
          session_id: session[:session_id],
          session_key: session[:session_key],
          shared_history: machine.shared_history?(room_id),
        })]
      end
    end

    client.to_device.send_to_device("m.room.encrypted", messages)

    Console.info(self, "Rotated a session.", room_id: room_id, because: because, recipients: recipients.size)
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # Anybody leaving may hold the session, so it must not encrypt anything further.
      in {room_id:, state_key:, content: Async::Matrix::Events::RoomMember(membership: "leave" | "ban")}
        share.call(room_id, because: "#{state_key} left")

      # An invite withdrawn counts as well: history sharing may already have handed them the keys.
      in {room_id:, state_key:, content: Async::Matrix::Events::RoomMember(membership: "invite"), prev_content: {membership: "join"}}
        share.call(room_id, because: "#{state_key} may have held keys")

      # A limited sync hides what happened in between, so any membership which is not a join is treated as a departure.
      in {room_id:, state_key:, content: Async::Matrix::Events::RoomMember}
        case batch.limited?(room_id)
        in true
          share.call(room_id, because: "a gap in the timeline around #{state_key}")
        in false
          nil
        end

      # The history became visible to future members, or stopped being: either way the flag on the session is now wrong.
      in {room_id:, content: Async::Matrix::Events::RoomHistoryVisibility(history_visibility:), prev_content: {history_visibility: String => before}}
        case SHAREABLE.include?(history_visibility) == SHAREABLE.include?(before)
        in false
          share.call(room_id, because: "the history visibility changed to #{history_visibility}")
        in true
          nil
        end

      # The room's own policy changed, so the next message is measured against the new one.
      in {room_id:, content: Async::Matrix::Events::RoomEncryption(rotation_period_ms:, rotation_period_msgs:)}
        machine.policy(room_id, period: rotation_period_ms, messages: rotation_period_msgs)

        Console.info(self, "The rotation policy changed.", room_id: room_id, period: rotation_period_ms, messages: rotation_period_msgs)

      else
        nil
      end
    end

    # Time and count are not events, so they are measured rather than matched: a session is checked before it is used again.
    machine.rooms_due_for_rotation.each do |room_id, because|
      share.call(room_id, because: because)
    end
  end
end
