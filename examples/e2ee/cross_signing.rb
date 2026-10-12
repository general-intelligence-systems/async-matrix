#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Signing our own devices, so that verifying a person once covers all of them.
#
# A user has three keys: a master key which is their identity, a self signing key which signs their own devices, and a user signing key which signs other people's master keys.
#
# So trust is a chain rather than a list: our master signed our user signing key, that signed their master key, that signed their self signing key, and that signed the device the message came from. Any break in it is a device we should not believe.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/cross_signing.rb

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

  # A hash pattern is keyed by label, so our own entry is read out before it is matched.
  ours = client.keys.query_keys({me => []}).master_keys[me.to_sym]

  # What the server already holds for us decides whether this is a first set or an existing one.
  case ours
  # Nothing yet, so the three keys are created and the private halves put into storage.
  in nil | {}
    identity = machine.create_cross_signing_keys

    client.cross_signing.upload_cross_signing_keys(
      master_key: identity.master,
      self_signing_key: identity.self_signing,
      user_signing_key: identity.user_signing,
    )

    # Without storage the only copy is on this device, and losing it means starting the identity again.
    machine.secrets.store(
      "m.cross_signing.master" => identity.private_master,
      "m.cross_signing.self_signing" => identity.private_self_signing,
      "m.cross_signing.user_signing" => identity.private_user_signing,
    ).each do |type, content|
      client.account_data.set_account_data(me, type, content)
    end

    Console.info(self, "Created a cross signing identity.", master: identity.master_key)

  # Already there, and ours to use only if the private halves can be had.
  in {keys: Hash => keys}
    case machine.secrets.load("m.cross_signing.self_signing")
    in String => secret
      machine.accept_cross_signing_secret("m.cross_signing.self_signing", secret)

      Console.info(self, "Loaded our self signing key from storage.", master: keys.values.first)

    # The keys exist but we cannot use them, so this device asks its siblings for them.
    in nil
      client.to_device.send_to_device("m.secret.request", machine.addressed(machine.devices.of(me), {
        action: "request",
        name: "m.cross_signing.self_signing",
        request_id: SecureRandom.uuid,
        requesting_device_id: machine.device_id,
      }))

      Console.warn(self, "Asked our other devices for the signing key.")
    end
  end

  # This device signs its own entry with the self signing key, which is what makes it cross signed.
  unless machine.cross_signed?(me, machine.device_id)
    client.cross_signing.upload_cross_signing_signatures(machine.sign_own_device)

    Console.info(self, "Cross signed this device.", device_id: machine.device_id)
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    case batch
    in {changed: [_, *] => changed}
      queried = client.keys.query_keys(changed.to_h{|user_id| [user_id, []]})
      machine.accept_queried_keys(queried)

      changed.each do |user_id|
        case machine.devices.identity(user_id)
        # Still the master key we already hold for ourselves, which is the ordinary case.
        in {user_id: ^me, master: ^(machine.own_master_key)}
          nil

        # Our own identity moved, which means somebody reset it: every device of ours must say so loudly.
        in {user_id: ^me, master: String}
          Console.error(self, "Our own master key changed. Nothing is trusted until this is resolved.")

        # Somebody we had verified now has a different identity, so the verification no longer holds.
        in {user_id:, master:, previously_verified: true}
          case machine.signed_by_us?(user_id, master)
          in false
            Console.error(self, "A verified user's identity changed.", user_id: user_id)

            machine.devices.untrust(user_id)
          in true
            nil
          end

        # A new identity for somebody we had not verified, which is taken on trust until it changes.
        in {user_id:, master:}
          Console.info(self, "A new identity for a user.", user_id: user_id, master: master)
        else
          nil
        end
      end
    else
      nil
    end

    machine.each_event(batch) do |event|
      case event
      # A sibling device answered with the secret, so this device can sign from now on.
      in {sender: ^me, content: Async::Matrix::Events::SecretSend(request_id:, secret:)}
        case machine.secrets.requested(request_id)
        in String => name
          machine.accept_cross_signing_secret(name, secret)
          client.cross_signing.upload_cross_signing_signatures(machine.sign_own_device)

          Console.info(self, "A sibling device sent the signing key.", name: name)

        # Nobody asked for this, so it is not taken: a secret arriving unbidden is somebody trying their luck.
        in nil
          Console.error(self, "A secret arrived which we never asked for.", request_id: request_id)
        end

      # A message from a device which no chain reaches, which the user should be told about rather than shown plainly.
      in {sender:, session_id:, content: Async::Matrix::Events::Message}
        case machine.cross_signed_sender?(event)
        in false
          Console.warn(self, "A message from a device we cannot place.", sender: sender, session_id: session_id)
        in true
          nil
        end

      else
        nil
      end
    end
  end
end
