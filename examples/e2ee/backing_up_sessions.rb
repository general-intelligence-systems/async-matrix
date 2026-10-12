#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Putting the room keys somewhere a new device can reach them without asking another device.
#
# The sessions are encrypted to a curve25519 key the server never sees, so the backup is useless to it: an ephemeral key, an ECDH against the backup's public key, and AES-CBC under what that derives.
#
# Which means anybody can add to a backup and only the holder of the private half can read it. So what has to be established before writing is that the backup is ours: either its `auth_data` is signed by our master key or a verified device of ours, or we hold a private key which derives its public one.
#
# The server decides what to keep when two devices back up the same session: a verified key beats an unverified one, then the lower first message index, then the lower forwarded count. So the index is what makes a backup worth replacing.
#
#   MATRIX_HOMESERVER=http://localhost:8008 ruby examples/e2ee/backing_up_sessions.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../lib/async/matrix/e2ee/olm"

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

  # Whether the user wants this at all, which v1.19 put in account data for every client to honour.
  case absent.call{client.account_data.get_account_data(me, "m.key_backup")}
  in {enabled: false}
    Console.info(self, "The user has turned key backup off.")

    next
  in {enabled: true} | nil
    nil
  end

  version = absent.call{client.key_backup.get_room_keys_version_current}

  backup = case version
  # One already exists, and writing to it means first establishing that it is ours.
  in {algorithm: ALGORITHM, version: String => id, auth_data: {public_key: String => public_key} => auth_data}
    # The private half is the strongest answer: a key which derives this public one is this backup's key.
    held = machine.secrets.held("m.megolm_backup.v1")

    case held
    in String => private_key
      case Async::Matrix::E2EE::Backup.from_private_key(private_key)
      in Async::Matrix::E2EE::Backup => derived if derived.public_key == public_key
        Console.info(self, "We hold the key for this backup.", version: id)

        derived
      in Async::Matrix::E2EE::Backup
        Console.error(self, "We hold a backup key, but not this backup's.", version: id)

        nil
      end

    # Otherwise it is the signature which says so, by the master key or by a device we have verified.
    in nil
      signed = machine.verify_signatures(auth_data, by: machine.own_master_key) ||
        machine.verify_signatures(auth_data, by: machine.devices.verified_of(me))

      case signed
      in true
        Console.info(self, "This backup is signed by us, so it can be written to.", version: id)

        Async::Matrix::E2EE::Backup.from_public_key(public_key, version: id)
      in false
        Console.error(self, "Nothing says this backup is ours, so it is left alone.", version: id)

        nil
      end
    end

  # None yet, so one is made, signed as ours, and its key put where another device can reach it.
  in nil
    made = Async::Matrix::E2EE::Backup.generate

    created = client.key_backup.post_room_keys_version(
      algorithm: ALGORITHM,
      auth_data: machine.sign_as_own(made.auth_data),
    )

    machine.secrets.store("m.megolm_backup.v1" => made.private_key).each do |type, content|
      client.account_data.set_account_data(me, type, content)
    end

    Console.info(self, "Made a backup.", version: created.version, public_key: made.public_key)

    made.at(created.version)

  in {algorithm: String => algorithm}
    Console.error(self, "The backup uses an algorithm we do not implement.", algorithm: algorithm)

    nil
  end

  case backup
  in nil
    Console.warn(self, "Nothing to back up to.")

  in Async::Matrix::E2EE::Backup => writing
    # Every session this device holds, as the backup wants them: the key in export format, and what is known about who sent it.
    sessions = machine.sessions.map{|session| machine.export_for_backup(session)}

    case sessions
    in []
      Console.info(self, "No sessions to back up yet.")

    in [_, *]
      # A hundred at a time, because a device which has been running a while holds a great many.
      sessions.each_slice(100) do |batch|
        rooms = batch.group_by{|session| session[:room_id]}.transform_values do |held|
          {sessions: held.to_h{|session| [session[:session_id], writing.encrypt(session)]}}
        end

        answered = client.key_backup.put_room_keys(version: writing.version, rooms: rooms)

        # What the server kept, which is not always what was sent: a better copy of a session wins.
        Console.info(self, "Backed up.", sessions: batch.size, count: answered.count, etag: answered.etag)
      end
    end
  end
end
