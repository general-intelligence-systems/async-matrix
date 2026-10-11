# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "async/matrix/e2ee"

require_relative "client_context"

module Async
  module Matrix
    # Two users, each with their own keys, which is the fewest encryption is between.
    E2EEContext = Sus::Shared("an encrypting client") do
      include Async::Matrix::ClientContext

      let(:crypto) {Async::Matrix::E2EE::Plaintext.new}

      let(:store) {Async::Matrix::E2EE::Store.new}

      let(:machine) {Async::Matrix::E2EE::Machine.new(client, crypto: crypto, store: store)}

      let(:other_username) {"other-#{SecureRandom.hex(6)}"}

      let(:other) {unauthenticated.logged_in(other_username, Async::Matrix::TEST_PASSWORD)}

      let(:other_user_id) {"@#{other_username}:localhost"}

      let(:other_device_id) {other.whoami.device_id}

      let(:other_crypto) {Async::Matrix::E2EE::Plaintext.new}

      let(:other_store) {Async::Matrix::E2EE::Store.new}

      let(:other_machine) {Async::Matrix::E2EE::Machine.new(other, crypto: other_crypto, store: other_store)}

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

      # Sync onwards from a batch which was already read, rather than from nothing.
      #
      # A device list change is only reported against a cursor which predates it, because an initial sync has nothing to report a change against.
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
          to.receive(sync)
        end
      end

      # Both users' keys published, which is what sending either of them a session needs.
      #
      # @returns [Array(Async::Matrix::ClientServer::UploadedKeys)] what each of them published.
      def published
        [machine.publish!, other_machine.publish!]
      end

      # A room both users have joined, which is where an encrypted message goes.
      #
      # @returns [Async::Matrix::ClientServer::Room] the room.
      def shared_room
        client.create_room(preset: "public_chat").tap do |room|
          other.join(room.id)
        end
      end
    end
  end
end
