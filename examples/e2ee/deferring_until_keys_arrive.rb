#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Keeping a message which cannot be read yet, and reading it when its key arrives.
#
# Decryption is not one message in, one message out: a ciphertext whose session has not arrived yields nothing, and the key which arrives later yields everything that was waiting for it.
#
# So "waiting" is an outcome with a pattern of its own, and a released message is older than the batch which carried its key: anything ordering by arrival will put history out of order.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/deferring_until_keys_arrive.rb

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

  # What the timeline would show, in the order the messages were sent rather than the order they could be read.
  timeline = []

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    # To-device messages are drained first, so a key which arrives in this batch releases the messages waiting in it.
    machine.each_event(batch) do |event|
      case event
      # Read straight away, because the session was already held.
      in {room_id:, sender:, origin_server_ts:, released: false, content: Async::Matrix::Events::TextMessage(body:)}
        timeline << {at: origin_server_ts, sender: sender, body: body}

        Console.info(self, "Read a message.", room_id: room_id, body: body)

      # Released: the key arrived in this batch, and this message was waiting for it from an earlier one.
      in {room_id:, sender:, origin_server_ts:, released: true, session_id:, content: Async::Matrix::Events::TextMessage(body:)}
        timeline << {at: origin_server_ts, sender: sender, body: body}

        Console.info(self, "Read a message which had been waiting.", room_id: room_id, session_id: session_id, body: body)

      # Still waiting. Nothing is wrong: the key may arrive in any later batch, or never.
      in {room_id:, session_id:, content: Async::Matrix::Events::Deferred}
        waiting = machine.store.deferred_count

        Console.info(self, "Waiting for a session.", room_id: room_id, session_id: session_id, waiting: waiting)

        # After long enough, ask the other devices of this user for it rather than waiting forever.
        case machine.store.waited(room_id, session_id)
        in Numeric => seconds
          if seconds > 10
            machine.request_keys(room_id, session_id: session_id).each do |type, messages|
              client.to_device.send_to_device(type, messages)
            end
          end
        else
          nil
        end

      # The key arrived. Whatever it released came through this same loop, above.
      in {sender:, content: Async::Matrix::Events::RoomKey(room_id:, session_id:)}
        Console.info(self, "A session arrived.", sender: sender, room_id: room_id, session_id: session_id)

      # It will never arrive, so the wait can stop and the user can be told why.
      in {sender:, content: Async::Matrix::Events::Withheld(room_id:, session_id:, code:)}
        Console.warn(self, "A session will not arrive.", sender: sender, room_id: room_id, code: code)

      else
        nil
      end
    end

    # A released message is older than the batch it arrived in, so the timeline is ordered by when it was sent.
    timeline.sort_by!{|message| message[:at]}
  end
end
