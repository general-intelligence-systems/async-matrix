#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Reading the room keys back out of a backup, which is what a new device does first.
#
# The decryption key comes from one of three places, and the specification trusts all three: the user typing it, secret storage, or a verified device of their own sending it over Olm.
#
# What comes back is trusted no further than the backup itself: a restored session carries no signature, so what it claims about who sent a message is only as good as whoever put it there. That is why `is_verified` is the server's first tie-break and why a restored key is imported as unverified here.
#
#   MATRIX_PASSPHRASE=correct-horse ruby examples/e2ee/restoring_from_backup.rb
#
#   MATRIX_BACKUP_KEY='EsTc LW2K PGiF wKEA 3As5 g5c4 BXwk qeeJ ZJV8 Q9fu gUMN UE4d'

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

PASSPHRASE = ENV.fetch("MATRIX_PASSPHRASE", nil)
TYPED = ENV.fetch("MATRIX_BACKUP_KEY", nil)

ALGORITHM = "m.megolm_backup.v1.curve25519-aes-sha2"

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  absent = lambda do |&block|
    begin
      block.call
    rescue Async::Matrix::RequestError => error
      case error.errcode
      in "M_NOT_FOUND"
        nil
      end
    end
  end

  version = absent.call{client.key_backup.get_room_keys_version_current}

  case version
  in nil
    Console.info(self, "There is no backup to restore from.")

    next
  in {algorithm: ALGORITHM, version: String, auth_data: {public_key: String}}
    nil
  in {algorithm: String => algorithm}
    Console.error(self, "The backup uses an algorithm we do not implement.", algorithm: algorithm)

    next
  end

  # Where the key came from decides nothing about how it is used, only how much the user had to do.
  key = case {typed: TYPED, passphrase: PASSPHRASE, held: machine.secrets.held("m.megolm_backup.v1")}
  # Typed in by hand, which is the representation in the appendices read backwards.
  in {typed: String => typed}
    case Async::Matrix::KeyRepresentation.decode(typed)
    in nil
      Console.error(self, "That is not a key: the header or the parity byte is wrong.")

      nil
    in String => bytes
      Console.info(self, "Using the key the user typed.")

      bytes
    end

  # Already in secret storage, which is where a client which set this up would have left it.
  in {held: String => held}
    Console.info(self, "Using the key from secret storage.")

    held

  # In storage but locked, so the passphrase opens it first.
  in {passphrase: String => passphrase}
    Console.info(self, "Opening secret storage with the passphrase.")

    machine.secrets.unlock(passphrase)

    machine.secrets.held("m.megolm_backup.v1")

  # None of the three, so the last resort is one of our own devices sending it.
  else
    client.to_device.send_to_device("m.secret.request", machine.addressed(machine.devices.verified_of(me), {
      action: "request",
      name: "m.megolm_backup.v1",
      request_id: SecureRandom.uuid,
      requesting_device_id: machine.device_id,
    }))

    Console.warn(self, "Asked our other devices for the backup key.")

    nil
  end

  case key
  in nil
    Console.warn(self, "Nothing to decrypt the backup with.")

  in String => private_key
    backup = Async::Matrix::E2EE::Backup.from_private_key(private_key).at(version[:version])

    # The public half it derives must be the one the backup was made with, or this is somebody else's key.
    case backup.public_key == version.dig(:auth_data, :public_key)
    in false
      Console.error(self, "That key does not belong to this backup.", version: version[:version])

    in true
      answered = client.key_backup.get_room_keys(version: backup.version)

      restored = answered.rooms.sum do |room_id, held|
        held[:sessions].count do |session_id, backed_up|
          case backed_up
          in {session_data: Hash => session_data, first_message_index: Integer => index, is_verified: verified}
            case backup.decrypt(session_data)
            # The MAC is over the empty string rather than the ciphertext, which is a bug every implementation now shares, so a wrong key fails here rather than earlier.
            in nil
              Console.error(self, "A session would not decrypt.", room_id: room_id, session_id: session_id)

              false

            in {algorithm: "m.megolm.v1.aes-sha2", session_key: String => session_key, sender_key:, sender_claimed_keys:, **rest}
              # Imported rather than accepted: an exported key carries no signature, so nothing here proves who sent what.
              machine.import_inbound_session(room_id.to_s,
                session_id: session_id.to_s,
                exported_key: session_key,
                sender_key: sender_key,
                sender_claimed_keys: sender_claimed_keys,
                shareable: rest.fetch(:shared_history, false),
                index: index,
                verified: verified,
              )

              true
            end
          end
        end
      end

      Console.info(self, "Restored from the backup.", version: backup.version, sessions: restored)
    end
  end
end
