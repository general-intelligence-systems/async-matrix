#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Sending and reading a file in an encrypted room.
#
# The event is encrypted by the room's session, but the file is not: it is uploaded on its own, with its own single use key, and the event carries the key rather than the bytes.
#
# So the key, the counter and a hash of the ciphertext travel inside the encrypted event, and the server holds a file it cannot read and cannot alter without the hash catching it. A thumbnail is a second file, and must not share the counter.
#
#   MATRIX_ROOM='!room:localhost' MATRIX_FILE=./picture.jpg ruby examples/e2ee/encrypted_attachments.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/vodozemac"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")
ROOM = ENV.fetch("MATRIX_ROOM", nil)
FILE = ENV.fetch("MATRIX_FILE", nil)

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Vodozemac.new,
  )

  case {room: ROOM, file: FILE}
  in {room: String => room_id, file: String => path}
    room = client.room(room_id)

    # The file gets its own key and counter, used once and never again.
    encrypted = machine.encrypt_file(File.read(path, mode: "rb"))
    uploaded = client.content_repo.upload(encrypted.ciphertext, content_type: "application/octet-stream")

    # A thumbnail is a second file with a key of its own, because sharing one counter with the image would break both.
    thumbnail = machine.encrypt_file(machine.thumbnail(path))
    thumbnailed = client.content_repo.upload(thumbnail.ciphertext, content_type: "application/octet-stream")

    # `file` replaces `url`, and carries the key as a JSON Web Key alongside the counter and the hash.
    content = Async::Matrix::Events::ImageMessage.build(
      body: File.basename(path),
      file: encrypted.describe(uploaded.content_uri),
      info: {
        mimetype: "image/jpeg",
        size: File.size(path),
        thumbnail_file: thumbnail.describe(thumbnailed.content_uri),
      },
    )

    # And then the event itself is encrypted by the room's session, as any other would be.
    sent = machine.encrypt(room_id, content)
    room.send_message(sent.type, sent.to_h)

    Console.info(self, "Sent an encrypted file.", room_id: room_id, url: uploaded.content_uri)
  else
    Console.info(self, "No room and file given, so this run only receives.")
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    machine.each_event(batch) do |event|
      case event
      # A file in an encrypted room. Version 2 is the current one, and AES counter mode is the only algorithm.
      in {sender:, session_id:, content: Async::Matrix::Events::ImageMessage(body:, file: {v: "v2", url:, key: {alg: "A256CTR"}, iv:, hashes: {sha256:}} => described)}
        ciphertext = client.content_repo.download(url)

        # The hash is checked before the bytes are used, since it is the only thing stopping the server from changing them.
        case machine.decrypt_file(ciphertext, file: described)
        in nil
          Console.error(self, "The file does not match its hash and was discarded.", url: url, sender: sender)
        in String => plaintext
          Console.info(self, "Read an encrypted file.", sender: sender, body: body, bytes: plaintext.bytesize)
        end

      # An older sender, from before the version was written down.
      in {sender:, content: Async::Matrix::Events::ImageMessage(file: {url:, hashes: Hash} => described)}
        Console.info(self, "A file from a client which names no version.", sender: sender, url: url)

      # No hash, which means the server could have changed it and nobody would know.
      in {sender:, content: Async::Matrix::Events::ImageMessage(file: Hash => described)}
        Console.error(self, "Refused a file with no hash.", sender: sender, url: described[:url])

      # A file in the clear, in a room we are encrypting.
      in {sender:, content: Async::Matrix::Events::ImageMessage(url: String => url)}
        Console.warn(self, "An unencrypted file arrived.", sender: sender, url: url)

      else
        nil
      end
    end
  end
end
