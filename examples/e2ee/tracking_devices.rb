#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Keeping up with which devices each user has.
#
# A message must be encrypted to every device of every member, so the list has to be current: `changed` names the users whose devices or cross signing keys moved, and `left` those we no longer share an encrypted room with.
#
# The list outlives the process, so a client which was offline asks `/keys/changes` from the cursor it stored rather than asking about everybody. Only one query per user may be in flight, or a slow answer can overwrite a newer one.
#
#   MATRIX_HOMESERVER=http://localhost:8008 MATRIX_USER=alice MATRIX_PASSWORD=password ruby examples/e2ee/tracking_devices.rb

require_relative "../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and the binding is required by name because it is optional.
require_relative "../../lib/async/matrix/e2ee"
require_relative "../../lib/async/matrix/e2ee/olm"

require "console"

HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
USER = ENV.fetch("MATRIX_USER", "alice")
PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

CURSOR = ENV.fetch("MATRIX_CURSOR", nil)

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
  client = unauthenticated.logged_in(USER, PASSWORD)
  owner = client.get_token_owner
  me = owner.user_id

  machine = Async::Matrix::E2EE::Machine.new(
    user_id: me,
    device_id: owner.device_id,
    crypto: Async::Matrix::E2EE::Olm.new,
  )

  # Ask about these users, one query at a time, and take on what comes back.
  refresh = lambda do |user_ids|
    outstanding = user_ids - machine.devices.querying

    unless outstanding.empty?
      queried = client.keys.query_keys(outstanding.to_h{|user_id| [user_id, []]})

      machine.accept_queried_keys(queried)

      case queried.failures.empty?
      # A homeserver which could not be reached leaves those users stale rather than empty.
      in false
        Console.warn(self, "Some homeservers did not answer.", servers: queried.failures.keys)
      in true
        Console.info(self, "Refreshed device lists.", users: outstanding.size)
      end
    end
  end

  # What changed while this client was not running, which only a stored cursor can answer.
  case CURSOR
  in String => from
    changes = client.keys.get_keys_changes(from: from, to: client.sync(timeout: 0).next_batch)

    case changes
    in {changed: [] , left: []}
      Console.info(self, "Nothing changed while we were away.")
    in {changed: Array => changed, left: Array => left}
      refresh.call(changed & machine.devices.tracking)
      machine.forget(left)

      Console.info(self, "Caught up.", changed: changed.size, left: left.size)
    end
  else
    Console.info(self, "No cursor, so the first sync establishes one.")
  end

  sync = client.sync(timeout: 0)

  sync.each(retries: 3) do |batch|
    case batch
    # Somebody added a device, replaced their cross signing keys, or began sharing an encrypted room with us.
    in {changed: [_, *] => changed, left: Array => left}
      refresh.call(changed)
      machine.forget(left)

      Console.info(self, "The device lists moved.", changed: changed, left: left)

    # No longer sharing any encrypted room, so there is nothing to encrypt to them and nothing to track.
    in {changed: [], left: [_, *] => left}
      machine.forget(left)

      Console.info(self, "We no longer share a room with somebody.", left: left)
    else
      nil
    end

    machine.each_event(batch) do |event|
      case event
      # A new member means a new set of devices to encrypt to, so they are tracked from now on.
      in {room_id:, state_key:, content: Async::Matrix::Events::RoomMember(membership: "join")}
        case machine.encrypted?(room_id)
        in true
          machine.devices.track(state_key)
          refresh.call([state_key])
        in false
          nil
        end

      # Our own master key changed, which every one of our devices must tell the user about.
      in {content: Async::Matrix::Events::Content => content}
        case content.type
        in "m.cross_signing_keys_changed"
          Console.error(self, "Our own cross signing keys changed. Re-verify this device.")
        else
          nil
        end

      else
        nil
      end
    end

    # The cursor is stored so that the next run can ask what it missed.
    Console.debug(self, "Store this cursor.", next_batch: batch.next_batch)
  end
end
