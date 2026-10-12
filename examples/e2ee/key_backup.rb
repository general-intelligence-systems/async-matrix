#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Keeping copies of the room keys on the server, so a new device can read old messages.
#
# A key request needs another device to be online; a backup does not. The price is that the sessions sit on the server, so they are encrypted to a key the server never sees.
#
# A backup is only written to once its `auth_data` is trusted, either because the master key signed it or because we derived its public key from a private one we already hold. Since v1.19 the user's own preference lives in account data, and a client is to honour it rather than decide for them.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/key_backup.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/vodozemac"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

ALGORITHM = "m.megolm_backup.v1.curve25519-aes-sha2"

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Vodozemac.new,
  )

  # The user's own preference, which a client honours rather than deciding for them.
  case client.account_data.get_account_data(me, "m.key_backup")
  in {enabled: true | false => enabled}
    wanted = enabled
  else
    # Absent or malformed, so the client may choose, and asking the user is the better choice.
    Console.info(self, "No stored preference about key backup.")

    wanted = true
  end

  unless wanted
    Console.info(self, "The user has turned key backup off.")
  end

  if wanted
    version = client.key_backup.get_room_keys_version

    case version
    # A backup exists, and whether to write to it depends entirely on whether its key can be trusted.
    in {algorithm: ALGORITHM, version: String => id, auth_data: {public_key: String => public_key} => auth_data}
      case machine.secrets.held("m.megolm_backup.v1")
      # We hold the private half, so deriving the public one from it is proof enough.
      in String => private_key
        trusted = machine.backup.derives?(private_key, public_key: public_key)

      # Otherwise the signature of the master key, or of a verified device of ours, is what makes it ours.
      in nil
        trusted = machine.verify_signatures(auth_data, by: machine.own_master_key) || machine.verify_signatures(auth_data, by: machine.verified_devices_of(me))
      end

      case trusted
      in false
        Console.error(self, "A backup exists whose key we cannot trust. Not writing to it.", version: id)
      in true
        machine.backup.use(id, public_key: public_key)

        Console.info(self, "Using the existing backup.", version: id)

        # What this device holds and the backup does not, which is what a first run uploads.
        machine.backup.pending.each_slice(100) do |sessions|
          client.key_backup.put_room_keys(version: id, rooms: machine.backup.encrypt(sessions))
        end
      end

    # None yet, so one is made and its key put into storage beside the cross signing keys.
    in nil
      backup = machine.backup.create

      created = client.key_backup.post_room_keys_version(
        algorithm: ALGORITHM,
        auth_data: machine.sign_as_own(backup.auth_data),
      )

      machine.secrets.store("m.megolm_backup.v1" => backup.private_key).each do |type, content|
        client.account_data.set_account_data(me, type, content)
      end

      machine.backup.use(created.version, public_key: backup.public_key)

      Console.info(self, "Created a backup.", version: created.version)

    in {algorithm: String => algorithm}
      Console.error(self, "The backup uses an algorithm we do not implement.", algorithm: algorithm)
    end
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # A session arrived, so a copy goes to the backup: the next device will not have to ask anybody for it.
      # An alternative pattern may not capture, so the rooms and sessions are read from the content it binds.
      in {content: Async::Matrix::Events::RoomKey | Async::Matrix::Events::ForwardedRoomKey => key}
        case machine.backup.using?
        in true
          client.key_backup.put_room_keys_by_room_id_and_session_id(
            version: machine.backup.version,
            room_id: key.room_id,
            session_id: key.session_id,
            **machine.backup.encrypt_one(key.room_id, key.session_id),
          )

          Console.debug(self, "Backed up a session.", room_id: key.room_id, session_id: key.session_id)
        in false
          nil
        end

      # A message we cannot read, which the backup may hold the key for even though no device answered.
      in {room_id:, session_id:, content: Async::Matrix::Events::Deferred}
        case machine.backup.using?
        in false
          nil
        in true
          case client.key_backup.get_room_keys_by_room_id_and_session_id(version: machine.backup.version, room_id: room_id, session_id: session_id)
          in {session_data: Hash => session_data, first_message_index: Integer => index}
            # Restored keys are unsigned, so what they can be trusted to say about their sender is only what the backup says.
            machine.import_from_backup(room_id, session_id: session_id, session_data: session_data, index: index)

            Console.info(self, "Restored a session from the backup.", room_id: room_id, session_id: session_id)
          else
            Console.debug(self, "The backup does not hold this session either.", session_id: session_id)
          end
        end

      # Somebody replaced the backup, so ours is no longer the one being written to.
      in {content: Async::Matrix::Events::KeyBackup(enabled:)}
        Console.info(self, "The key backup preference changed.", enabled: enabled)

      else
        nil
      end
    end
  end
end
