# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee"

module Async
  module Matrix
    # Stands in for a homeserver, so encryption needs none.
    module Offline
      # The one time keys a server is willing to hold for a device.
      TARGET = 50

      # Records what was uploaded and sent, and answers what was asked.
      class Homeserver
        def initialize
          @uploads = []
          @sent = []
          @queries = []
          @devices = {}
          @counts = {}
        end

        # @attribute [Array(Hash)] the key uploads this server received.
        attr :uploads

        # @attribute [Array(Array)] the type and messages of each device message sent.
        attr :sent

        # @attribute [Array(Array)] the users each query asked about.
        attr :queries

        # @attribute [Hash] how many one time keys this server holds, by algorithm.
        attr :counts

        # Give this server a device to answer a query with.
        #
        # @parameter user_id [String] the user whose device it is.
        # @parameter device_id [String] the device.
        # @parameter value [Hash] the device keys.
        def device(user_id, device_id, value = {})
          (@devices[user_id] ||= {})[device_id.to_sym] = value
        end

        # @parameter user_id [String] the user to answer for.
        # @returns [Hash] that user's devices, by device ID.
        def devices_of(user_id)
          @devices[user_id.to_s] || {}
        end
      end

      # The answer to uploading keys.
      class Uploaded
        def initialize(counts)
          @counts = counts
        end

        def one_time_key_counts = @counts
      end

      # The answer to querying keys.
      class Queried
        def initialize(homeserver)
          @homeserver = homeserver
        end

        def devices_of(user_id) = @homeserver.devices_of(user_id)
      end

      # The keys resource of an offline client.
      class Keys
        def initialize(homeserver)
          @homeserver = homeserver
        end

        def upload(**options)
          @homeserver.uploads << options

          published = options[:one_time_keys]&.size || 0
          @homeserver.counts[:signed_curve25519] = published

          Uploaded.new(@homeserver.counts)
        end

        def query(users)
          @homeserver.queries << users.keys

          Queried.new(@homeserver)
        end
      end

      # The device messaging resource of an offline client.
      class ToDevice
        def initialize(homeserver)
          @homeserver = homeserver
        end

        def send_event(type, messages, transaction_id: nil)
          @homeserver.sent << [type, messages]

          nil
        end
      end

      # The identity an offline client is authenticated as.
      class Whoami
        def initialize(user_id, device_id)
          @user_id = user_id
          @device_id = device_id
        end

        attr :user_id

        attr :device_id
      end

      # A client which makes no requests, and answers from its homeserver instead.
      class Client
        def initialize(homeserver, user_id: "@alice:localhost", device_id: "ALICE", version: Async::Matrix::LATEST)
          @homeserver = homeserver
          @user_id = user_id
          @device_id = device_id
          @version = version
        end

        # @attribute [Homeserver] the server which recorded what this client did.
        attr :homeserver

        attr :version

        def whoami = Whoami.new(@user_id, @device_id)

        def keys = Keys.new(@homeserver)

        def to_device = ToDevice.new(@homeserver)
      end

      # A sync batch, carrying only what encryption reads from one.
      class Batch
        def initialize(to_device: [], changed: [], left: [], counts: {})
          @to_device = to_device
          @changed = changed
          @left = left
          @counts = counts
        end

        attr :to_device

        def changed_devices = @changed

        def left_devices = @left

        def one_time_keys_count = @counts
      end
    end

    E2EEContext = Sus::Shared("an offline machine") do
      let(:homeserver) {Async::Matrix::Offline::Homeserver.new}

      let(:client) {Async::Matrix::Offline::Client.new(homeserver)}

      let(:crypto) {Async::Matrix::E2EE::Plaintext.new(one_time_key_target: Async::Matrix::Offline::TARGET)}

      let(:store) {Async::Matrix::E2EE::Store.new}

      let(:machine) {Async::Matrix::E2EE::Machine.new(client, crypto: crypto, store: store)}

      # The room every test encrypts into.
      let(:room_id) {"!room:localhost"}
    end
  end
end
