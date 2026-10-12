#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Reading the messages addressed to this device, which is how every key arrives.
#
# A to-device message carrying a key is an `m.room.encrypted` with the Olm algorithm, and what it decrypts to names its own sender and recipient.
#
# The specification lists checks which an incoming Olm plaintext MUST pass, and an event failing any of them MUST be discarded: here they are one pattern, so a payload which does not match is never believed.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/receiving_to_device.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/vodozemac"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

OLM = "m.olm.v1.curve25519-aes-sha2"

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Vodozemac.new,
  )

  our_keys = machine.crypto.identity_keys
  our_curve = our_keys[:curve25519]

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    batch.to_device.each do |value|
      event = machine.wrap(value)

      case event
      # An Olm message, whose ciphertext is addressed to each device by its curve25519 key.
      in {sender:, content: Async::Matrix::Events::RoomEncrypted(algorithm: OLM, sender_key:, ciphertext: Hash => ciphertext)}
        # A hash pattern is symbol keyed, so the part addressed to us is matched a step inside.
        addressed = ciphertext[our_curve.to_sym]

        case addressed
        # A type 0 carries the session, so it opens one when we have none.
        in {type: 0, body:}
          case machine.crypto.session?(sender_key)
          in false
            plaintext = machine.crypto.accept_session(identity_key: sender_key, body: body)
          in true
            plaintext = machine.crypto.decrypt_from_device(sender_key, type: 0, body: body)
          end

        # A type 1 needs a session already open, and can be read no other way.
        in {type: 1, body:}
          plaintext = machine.crypto.decrypt_from_device(sender_key, type: 1, body: body)

        # Nothing here is for us, which is normal: one event carries a copy per device.
        else
          next
        end

        payload = ::JSON.parse(plaintext, symbolize_names: true)

        # Who the sender claims to be, which must be who the envelope said, and what keys they claim, which must be the ones we hold.
        their = machine.devices.by_curve25519(sender, sender_key)

        case payload
        # Every check the specification requires, as one pattern. The sender, the sender's own key, us, and our own key.
        in {
          type: String => inner_type,
          content: Hash => content,
          sender: ^sender,
          recipient: ^me,
          keys: {ed25519: ^(their.ed25519)},
          recipient_keys: {ed25519: ^(our_keys[:ed25519])},
          **rest
        }
          # Since v1.15 a sender may carry its own signed device keys, which must agree with the envelope and with itself.
          case rest
          in {sender_device_keys: {user_id: ^sender, keys: Hash, signatures: Hash} => own}
            case machine.consistent?(own, sender_key: sender_key)
            in true
              Console.debug(self, "The sender proved its own keys.", sender: sender)
            in false
              Console.error(self, "Discarded: the sender's own keys disagree with the envelope.", sender: sender)

              next
            end
          in {sender_device_keys: Hash}
            Console.error(self, "Discarded: the sender's own keys do not name the sender.", sender: sender)

            next
          else
            Console.debug(self, "The sender carried no keys of its own, so they came from the server.", sender: sender)
          end

          Console.info(self, "Believed a device message.", sender: sender, type: inner_type)

          machine.receive_device_event(machine.content(inner_type, content), sender: sender)

        # Any mismatch is a forgery or a mistake, and either way the specification says to discard it.
        #
        # Addressed to us, so whatever did not match is on the sender's side of the payload.
        in {sender: String => claimed, recipient: ^me}
          Console.error(self, "Discarded: the plaintext does not name the sender we expected.", envelope: sender, claimed: claimed)

        in {recipient: String => recipient}
          Console.error(self, "Discarded: addressed to somebody else.", recipient: recipient)
        else
          Console.error(self, "Discarded: the plaintext does not name us and the sender correctly.", sender: sender)
        end

      # Sent in the clear, which only the events carrying no key may be.
      in {sender:, content: Async::Matrix::Events::RoomKeyRequest | Async::Matrix::Events::RoomKeyWithheld | Async::Matrix::Events::SecretRequest => content}
        Console.info(self, "An unencrypted device message, which is allowed for this type.", sender: sender, type: content.type)

        machine.receive_device_event(content, sender: sender)

      # A key bearing event which arrived in the clear is not to be trusted, whatever it says.
      in {sender:, content: Async::Matrix::Events::RoomKey | Async::Matrix::Events::ForwardedRoomKey | Async::Matrix::Events::SecretSend => content}
        Console.error(self, "Refused a key which did not arrive over Olm.", sender: sender, type: content.type)

      in {sender:, content: Async::Matrix::Events::Content => content}
        Console.debug(self, "Ignoring a device message we do not handle.", sender: sender, type: content.type)
      end
    end
  end
end
