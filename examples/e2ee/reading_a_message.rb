#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Reading the messages a room carries, encrypted or not.
#
# An event which arrived encrypted carries its session, so the pattern can ask how a message arrived as well as what it said.
#
# The Megolm plaintext carries the room, which is what stops a homeserver moving a message between rooms, and the ratchet index, which is what a replay is recognised by.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/reading_a_message.rb

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

  # Which index each session has already been read at, so that a message cannot be replayed at one.
  seen = {}

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # A message of our own, which comes back through sync like anybody else's.
      in {sender: ^me, content: Async::Matrix::Events::Message}
        nil

      # A message which arrived encrypted. `session_id` says so without having to ask, so this arm precedes the cleartext one.
      in {room_id:, sender:, session_id:, message_index:, content: Async::Matrix::Events::TextMessage(body:)}
        read = (seen[session_id] ||= [])

        # Replayed: this session has already produced a message at this index, so the homeserver is repeating itself.
        case read.include?(message_index)
        in true
          Console.error(self, "Rejected a replayed message.", room_id: room_id, session_id: session_id, index: message_index)
        in false
          read << message_index

          Console.info(self, "Read a message.", room_id: room_id, sender: sender, body: body, index: message_index)
        end

      # An image, whose file is encrypted on its own, separately from the event which describes it.
      in {sender:, session_id:, content: Async::Matrix::Events::ImageMessage(body:, file: {url:})}
        Console.info(self, "An encrypted image arrived.", sender: sender, body: body, url: url)

      # The same message, sent in the clear into a room we are encrypting.
      in {room_id:, sender:, content: Async::Matrix::Events::TextMessage(body:)}
        Console.warn(self, "A message arrived unencrypted.", room_id: room_id, sender: sender, body: body)

      # Anything else we could read, which is most of what a room carries.
      in {sender:, content: Async::Matrix::Events::Content => content}
        Console.debug(self, "Read an event.", sender: sender, type: content.type)
      end
    end
  end
end
