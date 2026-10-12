#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Writing the room keys to a file, and reading somebody's file back in.
#
# This is the way out which needs no server: the sessions go into a file encrypted under a passphrase, and whoever has the file and the passphrase can read the messages.
#
# The file says so in plain text at both ends, is armoured in base64 between them, and derives its keys with a great many rounds of PBKDF2 because a passphrase is all that protects it.
#
# An imported session carries no signature, so what it says about who sent a message is only as good as the file it came from.
#
#   MATRIX_EXPORT=./keys.txt MATRIX_PASSPHRASE=secret ruby examples/e2ee/exporting_keys.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

EXPORT = ENV.fetch("MATRIX_EXPORT", nil)
IMPORT = ENV.fetch("MATRIX_IMPORT", nil)
PASSPHRASE = ENV.fetch("MATRIX_PASSPHRASE", nil)

# The specification asks for at least this many, and more is better.
ROUNDS = 500_000

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  case {export: EXPORT, import: IMPORT, passphrase: PASSPHRASE}
  # Writing everything this device holds, each session exported from the earliest index it can still reach.
  in {export: String => path, passphrase: String => passphrase}
    sessions = machine.sessions.map{|session| machine.export_session(session)}

    File.write(path, machine.exports.dump(sessions, passphrase: passphrase, rounds: ROUNDS))

    Console.info(self, "Wrote an export.", path: path, sessions: sessions.size)

  # Reading one in. Everything about it is suspect until the passphrase proves otherwise.
  in {import: String => path, passphrase: String => passphrase}
    case machine.exports.load(File.read(path), passphrase: passphrase)
    # The header is not what an export begins with, so this is not one.
    in nil
      Console.error(self, "That file is not a key export.", path: path)

    # The code over the whole file did not match, which is a wrong passphrase or a damaged file.
    in {version: 1, authentic: false}
      Console.error(self, "That passphrase does not open this export, or the file is damaged.")

    in {version: 1, authentic: true, sessions: Array => sessions}
      imported = sessions.count do |session|
        case session
        # Everything an import must carry. A session missing any of it is not one we can use.
        in {algorithm: "m.megolm.v1.aes-sha2", room_id:, session_id:, session_key:, sender_key:, sender_claimed_keys: Hash => claimed, forwarding_curve25519_key_chain: Array}
          # The flag travels with the session, so an imported key keeps whatever its creator said about sharing it.
          case session
          in {shared_history: true}
            shareable = true
          else
            shareable = false
          end

          machine.import_inbound_session(room_id,
            session_id: session_id,
            exported_key: session_key,
            sender_key: sender_key,
            sender_claimed_keys: claimed,
            shareable: shareable,
          )

          true
        in {session_id:}
          Console.warn(self, "Skipped a session which is missing fields.", session_id: session_id)

          false
        else
          false
        end
      end

      Console.info(self, "Imported.", path: path, sessions: imported, of: sessions.size)
    end
  else
    Console.info(self, "Nothing to export or import, so this run only reads the timeline.")
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      in {sender:, session_id:, content: Async::Matrix::Events::TextMessage(body:)}
        # Read with an imported key, so nothing here proves who actually sent it.
        case machine.imported?(session_id)
        in true
          Console.info(self, "Read with an imported key, so the sender is unproven.", claimed: sender, body: body)
        in false
          Console.info(self, "Read a message.", sender: sender, body: body)
        end

      else
        nil
      end
    end
  end
end
