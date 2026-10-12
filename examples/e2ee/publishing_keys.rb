#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Publishing this device's keys, and keeping the server stocked with them.
#
# A device publishes one identity, a batch of one time keys which are claimed once each, and a fallback key which is not consumed by use.
#
# Every batch says what the server still holds, so the batch itself is the pattern: `device_one_time_keys_count` for the one time keys, and `device_unused_fallback_key_types` for whether the fallback key has been claimed.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/publishing_keys.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/vodozemac"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: owner.user_id,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Vodozemac.new,
  )

  target = machine.crypto.one_time_key_target

  # The identity keys are signed by the device's own ed25519 key, so another device can tell they belong together.
  machine.crypto.generate_one_time_keys(target)
  machine.crypto.generate_fallback_key

  uploaded = client.keys.upload_keys(
    device_keys: machine.device_keys,
    one_time_keys: machine.signed_one_time_keys,
    fallback_keys: machine.signed_fallback_key,
  )

  # The private halves of the published keys are forgotten, so that none is ever handed out twice.
  machine.crypto.published_one_time_keys!

  Console.info(self, "Published.", device_id: owner.device_id, counts: uploaded.one_time_key_counts)

  sync = client.sync(timeout: 0)

  sync.each do |batch|
    case batch
    in {one_time_keys_count: {signed_curve25519: Integer => held}}
      # Below half the target, because a device which waits until zero cannot be spoken to in the meantime.
      if held < target / 2
        machine.crypto.generate_one_time_keys(target - held)
        client.keys.upload_keys(one_time_keys: machine.signed_one_time_keys)
        machine.crypto.published_one_time_keys!

        Console.info(self, "Topped up the one time keys.", held: held)
      end

    # No count at all means the server holds none, which is the same emergency arrived at silently.
    in {one_time_keys_count: {}}
      machine.crypto.generate_one_time_keys(target)
      client.keys.upload_keys(one_time_keys: machine.signed_one_time_keys)
      machine.crypto.published_one_time_keys!

      Console.warn(self, "The server held no one time keys at all.")
    else
      nil
    end

    case batch
    # The fallback key is listed for as long as it is unused, so finding it means there is nothing to do.
    in {unused_fallback_key_types: [*, "signed_curve25519", *]}
      nil

    # Its absence from the list is what says the server handed it out.
    in {unused_fallback_key_types: Array}
      machine.crypto.generate_fallback_key
      client.keys.upload_keys(fallback_keys: machine.signed_fallback_key)

      # The one before last is dropped once the replacement is published, since a fallback key decrypts replays for as long as it is held.
      machine.crypto.forget_fallback_key

      Console.info(self, "Replaced the fallback key, which had been claimed.")
    else
      nil
    end
  end
end
