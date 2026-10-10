# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "paths"
require_relative "representation"
require_relative "rooms"
require_relative "versioned"
require_relative "abstract/sync"

module Async
  module Matrix
    # A single sync batch: the delta of everything visible to the user since the previous batch.
    #
    # `/sync` is a long poll. The server holds the request open for up to `timeout` milliseconds
    # waiting for something to happen, so a sync loop is a sequence of requests, each one starting
    # from the {#next_batch} token of the last.
    class Sync < Representation
      include Versioned

      # How long the server should hold a sync request open, in milliseconds.
      DEFAULT_TIMEOUT = 30_000

      # The absolute path of the sync endpoint.
      def self.path
        "#{V3}/sync"
      end

      # Begin syncing.
      #
      # @parameter resource [Async::REST::Resource] an authenticated resource, typically a {Client}.
      # @parameter since [String | nil] the batch token to start from, or nil for the initial sync.
      # @parameter timeout [Integer] how long the server should wait, in milliseconds.
      # @returns [Sync] the first batch.
      def self.start(resource, since: nil, timeout: DEFAULT_TIMEOUT, **parameters)
        parameters[:timeout] = timeout
        parameters[:since] = since if since

        self.get(resource.with(path: self.path, parameters: parameters))
      end

      # @returns [String] the token which the following batch should start from.
      def next_batch
        self.value[:next_batch]
      end

      # @returns [Hash] the rooms the user has joined, keyed by room ID.
      def joined
        self.value.dig(:rooms, :join) || {}
      end

      # @returns [Hash] the rooms the user has been invited to, keyed by room ID.
      def invited
        self.value.dig(:rooms, :invite) || {}
      end

      # @returns [Boolean] whether anything happened in this batch.
      def empty?
        self.joined.empty? and self.invited.empty?
      end

      # Enumerate over every timeline event in this batch.
      #
      # Note that the room IDs are symbols, because the JSON parser symbolizes all names, so they
      # are converted back to strings here.
      #
      # @yields {|room_id, event| ...}
      #   @parameter room_id [String] the ID of the room the event occurred in.
      #   @parameter event [Hash] the event.
      def each_event
        return to_enum(:each_event) unless block_given?

        self.joined.each do |room_id, room|
          events = room.dig(:timeline, :events) or next

          events.each do |event|
            yield room_id.to_s, event
          end
        end
      end

      # Enumerate over every message in this batch.
      #
      # @yields {|room_id, sender, body, event| ...}
      def each_message
        return to_enum(:each_message) unless block_given?

        self.each_event do |room_id, event|
          next unless event[:type] == "m.room.message"

          content = event[:content] || {}

          yield room_id, event[:sender], content[:body], event
        end
      end

      # The following batch, continuing from this one. This will block until the server has
      # something to report, or until the timeout expires.
      #
      # @parameter timeout [Integer] how long the server should wait, in milliseconds.
      # @returns [Sync] the following batch.
      def following(timeout: DEFAULT_TIMEOUT, **parameters)
        parameters[:since] = self.next_batch
        parameters[:timeout] = timeout

        self.class.get(@resource.with(parameters: parameters))
      end

      # Sync repeatedly, yielding each batch as it arrives. This does not return.
      #
      # @yields {|sync| ...}
      #   @parameter sync [Sync] the batch.
      def each(**options)
        return to_enum(:each, **options) unless block_given?

        sync = self

        while true
          yield sync

          sync = sync.following(**options)
        end
      end
    end
  end
end
