# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "securerandom"

require "async/matrix/e2ee"

require_relative "client_context"

module Async
  module Matrix
    # Two users, each with their own keys, which is the fewest encryption is between.
    E2EEContext = Sus::Shared("an encrypting client") do
      include Async::Matrix::ClientContext

      let(:crypto) {Async::Matrix::E2EE::Plaintext.new(one_time_key_target: 2)}

      let(:store) {Async::Matrix::E2EE::Store.new}

      let(:machine) {self.machine_for(client, crypto: crypto, store: store)}

      let(:other_username) {"other-#{SecureRandom.hex(6)}"}

      let(:other) {self.account(other_username)}

      let(:other_user_id) {"@#{other_username}:localhost"}

      let(:other_device_id) {other.get_token_owner.device_id}

      let(:other_crypto) {Async::Matrix::E2EE::Plaintext.new(one_time_key_target: 2)}

      let(:other_store) {Async::Matrix::E2EE::Store.new}

      let(:other_machine) {self.machine_for(other, crypto: other_crypto, store: other_store)}

      # A machine for a client, told who it is rather than asking.
      #
      # @parameter as [Async::Matrix::ClientServer::Client] whose device it encrypts as.
      # @returns [Async::Matrix::E2EE::Machine] the machine.
      def machine_for(as, **options)
        owner = as.get_token_owner

        Async::Matrix::E2EE::Machine.new(user_id: owner.user_id, device_id: owner.device_id, version: Async::Matrix::TEST_VERSION, **options)
      end

      # Query these users' devices and hand the answer to a machine, which makes no request of its own.
      #
      # @parameter user_ids [Array(String)] the users to ask about.
      # @parameter into [Async::Matrix::E2EE::Machine] the machine to tell.
      # @parameter as [Async::Matrix::ClientServer::Client] the client to ask through.
      # @returns [Async::Matrix::ClientServer::QueriedKeys] what was answered.
      def accept_devices(user_ids, into: machine, as: client)
        as.keys.query_keys(user_ids.each_with_object({}){|user_id, asked| asked[user_id] = []}).tap do |queried|
          into.accept_queried_keys(queried)
        end
      end

      # Publish a machine's keys, which is two steps: it generates, and the client uploads.
      #
      # @parameter machine [Async::Matrix::E2EE::Machine] whose keys to publish.
      # @parameter as [Async::Matrix::ClientServer::Client] the client to upload through.
      # @returns [Async::Matrix::ClientServer::UploadedKeys] what the server now holds.
      def publish(machine, as: client)
        machine.crypto.generate_one_time_keys(machine.crypto.one_time_key_target)

        as.keys.upload_keys(
          device_keys: machine.device_keys,
          one_time_keys: machine.signed_one_time_keys,
        ).tap do
          machine.crypto.published_one_time_keys!
        end
      end

      # Share a room's session with the devices of the given users.
      #
      # @parameter machine [Async::Matrix::E2EE::Machine] whose session to share.
      # @parameter room_id [String] the room.
      # @parameter user_ids [Array(String)] whose devices to share with.
      # @parameter as [Async::Matrix::ClientServer::Client] the client to send through.
      # @parameter rotate [Boolean] whether to begin a new session first.
      # @returns [Hash] the session which was shared.
      def share(machine, room_id, user_ids, as: client, rotate: false)
        queried = as.keys.query_keys(user_ids.each_with_object({}){|user_id, asked| asked[user_id] = []})
        recipients = machine.recipients(queried)

        wanted = machine.without_sessions(recipients)

        unless wanted.empty?
          machine.accept_claimed_keys(as.keys.claim_keys(wanted))
        end

        machine.session_for(room_id, rotate: rotate).tap do |session|
          unless recipients.empty?
            # Over Olm, so what is sent is an `m.room.encrypted` rather than an `m.room_key`.
            as.to_device.send_to_device("m.room.encrypted", recipients.each_with_object({}) do |device, messages|
              content = machine.encrypt_to_device(device, "m.room_key", {
                algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
                room_id: room_id,
                session_id: session[:session_id],
                session_key: session[:session_key],
              })

              (messages[device.user_id] ||= {})[device.device_id] = content
            end)
          end
        end
      end

      # Hand a batch to a machine, which is what a sync loop does with its device messages.
      #
      # @parameter machine [Async::Matrix::E2EE::Machine] the machine to feed.
      # @parameter sync [Async::Matrix::ClientServer::Sync] the batch.
      # @returns [Array(Async::Matrix::Events::Envelope)] what the device messages released.
      def receive_into(machine, sync)
        machine.devices.invalidate(changed: sync.changed_devices, left: sync.left_devices)

        machine.each_event(sync).select do |event|
          event.is_a?(Async::Matrix::Events::Decrypted) && event.released?
        end
      end

      # Sync until a batch satisfies the condition, or give up.
      #
      # A write is not visible to `/sync` the instant it completes, so a test waits for it.
      #
      # @parameter from [Async::Matrix::ClientServer::Client] whose batches to read.
      # @parameter attempts [Integer] how many batches to read.
      # @parameter timeout [Integer] how long each batch may wait, in milliseconds.
      # @yields {|sync| ...}
      #   @parameter sync [Async::Matrix::ClientServer::Sync] the batch to judge.
      # @returns [Async::Matrix::ClientServer::Sync | nil] the batch which satisfied it, or nil.
      def sync_until(from, attempts: 5, timeout: 1000, &block)
        batches = Enumerator.produce(from.sync(timeout: 0)){|sync| sync.following(timeout: timeout)}

        # Lazily, so that finding it early does not ask for the batches after it:
        batches.lazy.take(attempts).find(&block)
      end

      # Sync onwards from a batch already read, rather than from nothing.
      #
      # A device list change is only reported against a cursor which predates it.
      #
      # @parameter since [Async::Matrix::ClientServer::Sync] the batch to continue from.
      # @parameter attempts [Integer] how many batches to read.
      # @parameter timeout [Integer] how long each batch may wait, in milliseconds.
      # @yields {|sync| ...}
      #   @parameter sync [Async::Matrix::ClientServer::Sync] the batch to judge.
      # @returns [Async::Matrix::ClientServer::Sync | nil] the batch which satisfied it, or nil.
      def sync_after(since, attempts: 5, timeout: 1000, &block)
        batches = Enumerator.produce(since.following(timeout: timeout)){|sync| sync.following(timeout: timeout)}

        batches.lazy.take(attempts).find(&block)
      end

      # Sync until a device message arrives, and hand the batch to the machine which was waiting.
      #
      # @parameter to [Async::Matrix::E2EE::Machine] the machine to feed.
      # @parameter from [Async::Matrix::ClientServer::Client] whose batches to read.
      # @returns [Async::Matrix::ClientServer::Sync | nil] the batch which carried it.
      def receive_device_message(to, from)
        sync_until(from){|sync| !sync.to_device.empty?}&.tap do |sync|
          self.receive_into(to, sync)
        end
      end

      # The other user's view of a room, so that they send as themselves rather than as us.
      #
      # @parameter room [Async::Matrix::ClientServer::Room] the room, as we see it.
      # @returns [Async::Matrix::ClientServer::Room] the room, as they see it.
      def other_room(room)
        other.room(room.id)
      end

      # Both users' keys published, which is what sending either of them a session needs.
      #
      # @returns [Array(Async::Matrix::ClientServer::UploadedKeys)] what each of them published.
      def published
        [self.publish(machine), self.publish(other_machine, as: other)]
      end

      # A room both users have joined, which is where an encrypted message goes.
      #
      # @returns [Async::Matrix::ClientServer::Room] the room.
      def shared_room
        client.create_room(preset: "public_chat").tap do |room|
          other.join_room(room.id)
        end
      end
    end
  end
end
