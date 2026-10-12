#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Giving somebody the keys to the messages sent before they were invited.
#
# Added in v1.19 by MSC4268: the keys are bundled into a file, encrypted the way an attachment is, uploaded, and the bundle pointed at with an `m.room_key_bundle` sent before the invite goes out.
#
# Only sessions marked shareable go in, which is the sender's own record of whether the history was visible when they sent it: a homeserver cannot talk a client into sharing more than it meant to.
#
# A bundle is a file, so it is fetched when the invite is accepted rather than when it arrives. Otherwise anybody could make us download anything.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password MATRIX_INVITEE=@bob:localhost ruby examples/e2ee/sharing_history.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")
INVITEE = ENV.fetch("MATRIX_INVITEE", nil)
ROOM = ENV.fetch("MATRIX_ROOM", nil)

DAY = 86_400

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # Bundles somebody told us about, which are fetched if and when we accept the invite they belong to.
  offered = {}

  case {room: ROOM, invitee: INVITEE}
  # Inviting somebody, so the keys go out before the invite does.
  in {room: String => room_id, invitee: String => invitee}
    room = client.room(room_id)

    # The history has to allow it, whatever our own sessions say.
    case room.get_room_state_with_key("m.room.history_visibility")
    in {content: {history_visibility: "shared" | "world_readable"}}
      # Everything we hold for the room, split by whether its creator meant it to travel.
      shareable, withheld = machine.sessions_in(room_id).partition(&:shareable?)

      bundle = {
        room_keys: shareable.map{|session| machine.export_for_bundle(session)},
        withheld: withheld.map do |session|
          {
            room_id: room_id,
            session_id: session.session_id,
            algorithm: "m.megolm.v1.aes-sha2",
            code: "m.history_not_shared",
            reason: "The session was not marked as shareable.",
          }
        end,
      }

      # Encrypted and uploaded exactly as an attachment is, so the server holds a file it cannot read.
      file = machine.encrypt_file(::JSON.dump(bundle))
      uploaded = client.content_repo.upload(file.ciphertext, content_type: "application/octet-stream")

      # Only cross signed devices are told, because a bundle is a great deal of history to hand to an impostor.
      queried = client.keys.query_keys({invitee => []})
      recipients = machine.recipients(queried).select(&:cross_signed?)

      wanted = machine.without_sessions(recipients)

      unless wanted.empty?
        machine.accept_claimed_keys(client.keys.claim_keys(wanted))
      end

      messages = recipients.group_by(&:user_id).transform_values do |devices|
        devices.to_h do |device|
          [device.device_id, machine.encrypt_to_device(device, "m.room_key_bundle", {
            room_id: room_id,
            file: file.describe(uploaded.content_uri),
          })]
        end
      end

      client.to_device.send_to_device("m.room.encrypted", messages)

      # The invite goes afterwards, so the keys are already waiting when it is accepted.
      client.inviting.invite_user(room_id, invitee)

      Console.info(self, "Shared history and invited.", room_id: room_id, keys: shareable.size, withheld: withheld.size)

    in {content: {history_visibility: String => visibility}}
      client.inviting.invite_user(room_id, invitee)

      Console.info(self, "Invited without history, which this room does not allow.", visibility: visibility)
    end
  else
    Console.info(self, "No room and invitee given, so this run only receives.")
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # Somebody is offering us the history of a room. The sender's own device keys must be in the Olm plaintext, or it is ignored.
      in {sender:, sender_device_keys: true, content: Async::Matrix::Events::RoomKeyBundle(room_id:, file:)}
        offered[room_id] = {sender: sender, file: file, at: Time.now}

        Console.info(self, "History is on offer.", sender: sender, room_id: room_id)

        # Already a member, so it is wanted now rather than later.
        case machine.joined?(room_id)
        in true
          machine.import_bundle(room_id, client.content_repo.download(file[:url]), file: file, from: sender)
        in false
          nil
        end

      # A bundle with no proof of who built it, which is not worth the download.
      in {sender:, content: Async::Matrix::Events::RoomKeyBundle(room_id:)}
        Console.error(self, "A bundle arrived without the sender's own keys.", sender: sender, room_id: room_id)

      # We accepted an invite, so a bundle offered for it is now worth fetching.
      in {room_id:, state_key: ^me, content: Async::Matrix::Events::RoomMember(membership: "join")}
        case offered.delete(room_id)
        in {sender:, file:, at:}
          # Recent enough to be about this invite. A day is the suggested limit.
          case Time.now - at < DAY
          in true
            machine.import_bundle(room_id, client.content_repo.download(file[:url]), file: file, from: sender)

            # Whose word the history rests on, which the user is to be shown.
            Console.info(self, "Imported history, on this person's word alone.", room_id: room_id, from: sender)
          in false
            Console.info(self, "An old offer, which this join is probably not about.", sender: sender)
          end
        else
          nil
        end

      else
        nil
      end
    end
  end
end
