#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# An echo bot: it joins any room it is invited to, and replies to every message it sees.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=echo MATRIX_PASSWORD=password ruby examples/echo.rb

require_relative "../lib/async/matrix"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "echo")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  me = client.whoami.user_id

  Console.info(self, "Logged in.", user_id: me)

  # The initial sync reports all current state, which we skip over: we only want what happens from
  # now on, so the first batch is used for its cursor alone.
  sync = client.sync(timeout: 0)

  while true
    sync = sync.following(timeout: 30_000)

    sync.invited.each_key do |room_id|
      Console.info(self, "Invited to a room, joining.", room_id: room_id)

      client.join(room_id.to_s)
    end

    sync.each_message do |message|
      case message
      in {sender: ^me}
        # Don't reply to ourselves, or we will talk forever.
      in {room_id:, sender:, content: Async::Matrix::Events::TextMessage(body:)}
        Console.info(self, "Received a message.", room_id: room_id, sender: sender, body: body)

        client.room(room_id).send(Async::Matrix::Events::TextMessage.build(body: "You said: #{body}"))
      in {sender:, content: Async::Matrix::Events::Message(msgtype:)}
        Console.info(self, "Ignoring a message we do not handle.", sender: sender, msgtype: msgtype)
      end
    end
  end
end
