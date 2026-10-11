# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/old_sync"

module Async
  module Matrix
    module ClientServer
      # A page of events from the deprecated synchronisation.
      class EventPage < Representation
        include Versioned

        # @returns [Array(Hash)] the events in this page.
        def chunk
          self.value[:chunk] || []
        end

        # @returns [String | nil] the token this page starts at.
        def start
          self.value[:start]
        end

        # @returns [String | nil] the token to ask for the next page from.
        def finish
          self.value[:end]
        end

        # @returns [Boolean] whether the page is empty.
        def empty?
          self.chunk.empty?
        end
      end

      # Everything the deprecated synchronisation says at once.
      class InitialSync < Representation
        include Versioned

        # @returns [Array(Hash)] the rooms this user is in, each with its state and recent events.
        def rooms
          self.value[:rooms] || []
        end

        # @returns [Array(Hash)] the presence of the users this one shares a room with.
        def presence
          self.value[:presence] || []
        end

        # @returns [Array(Hash)] this user's own data.
        def account_data
          self.value[:account_data] || []
        end

        # @returns [String | nil] the token to carry on from.
        def finish
          self.value[:end]
        end
      end

      # The synchronisation the specification deprecated, which predates `/sync`.
      class OldSync
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [OldSync] the streams.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Everything at once, which is what a client asked for before `/sync`.
        #
        # @parameter limit [Integer | nil] the most events wanted per room.
        # @parameter archived [Boolean | nil] whether to include the rooms this user has left.
        # @returns [InitialSync] the state of everything.
        def initial_sync(limit: nil, archived: nil)
          parameters = {limit: limit, archived: archived}.compact

          api::InitialSync.get(@resource.with(path: "#{V3}/initialSync", parameters: parameters))
        end

        # The events since a token, which is what a client polled before `/sync`.
        #
        # @parameter from [String | nil] the token to read from.
        # @parameter timeout [Integer | nil] how long to wait for an event, in milliseconds.
        # @returns [EventPage] the page of events.
        def get_events(from: nil, timeout: nil)
          parameters = {from: from, timeout: timeout}.compact

          api::EventPage.get(@resource.with(path: "#{V3}/events", parameters: parameters))
        end

        # One event, by ID, wherever it is.
        #
        # @parameter event_id [String] the event to read.
        # @returns [Event] the event.
        def get_one_event(event_id)
          path = "#{V3}/events/#{::Protocol::URL::Encoding.escape(event_id)}"

          api::Event.get(@resource.with(path: path))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
