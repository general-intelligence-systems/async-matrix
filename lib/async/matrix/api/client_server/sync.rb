# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "rooms"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/sync"

module Async
  module Matrix
    module ClientServer
      # A single sync batch: the delta since the previous one.
      #
      # `/sync` is a long poll, so a loop is a sequence of requests, each starting from the last {#next_batch}.
      class Sync < Representation
        include Versioned

        # How long the server should hold a sync request open, in milliseconds.
        DEFAULT_TIMEOUT = 30_000

        # The absolute path of the sync endpoint.
        #
        # @returns [String] the path.
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
          if since
            parameters[:since] = since
          end

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

        # @returns [Hash] the events addressed to this device, which carry encryption keys.
        def to_device
          self.value.dig(:to_device, :events) || []
        end

        # @returns [Array(String)] the users whose device lists changed.
        def changed_devices
          self.value.dig(:device_lists, :changed) || []
        end

        # @returns [Array(String)] the users who are no longer shared with.
        def left_devices
          self.value.dig(:device_lists, :left) || []
        end

        # @returns [Hash] how many one time keys the server still holds, by algorithm.
        def one_time_keys_count
          self.value[:device_one_time_keys_count] || {}
        end

        # @returns [Boolean] whether anything happened in this batch.
        def empty?
          self.joined.empty? and self.invited.empty?
        end

        # Enumerate over every timeline event in this batch.
        #
        # Note that the room IDs are symbols, because the JSON parser symbolizes all names, so they are converted back to strings here.
        #
        # @yields {|event| ...}
        #   @parameter event [Events::Envelope] the event, which names the room it came from.
        def each_event
          if block_given?
            self.joined.each do |room_id, room|
              events = room.dig(:timeline, :events) or next

              events.each do |event|
                # `/sync` groups events by room rather than naming the room on each one, so the envelope is told which room it came from:
                yield self.events.wrap(event, room_id: room_id.to_s)
              end
            end
          else
            to_enum(:each_event)
          end
        end

        # Enumerate over every message in this batch.
        #
        # @yields {|event| ...}
        #   @parameter event [Events::Envelope] the message, whose content is an {Events::Message}.
        def each_message
          if block_given?
            self.each_event do |event|
              unless event.content.is_a?(Events::Message)
                next
              end

              yield event
            end
          else
            to_enum(:each_message)
          end
        end

        # The following batch, continuing from this one. This will block until the server has something to report, or until the timeout expires.
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
          if block_given?
            sync = self
            while true
              yield sync

              sync = sync.following(**options)
            end
          else
            to_enum(:each, **options)
          end
        end
      end
    end
  end
end
