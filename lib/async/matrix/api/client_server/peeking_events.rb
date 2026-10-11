# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # A page of events read without joining.
      class PeekedEvents < Representation
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

      # Reading the events of a room without joining it.
      class PeekingEvents
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [PeekingEvents] the peek.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Read the events of a world readable room without joining it.
        #
        # @parameter from [String] the token to read from, which a previous page ends at.
        # @parameter room_id [String | nil] the room to read, which the homeserver requires to peek.
        # @parameter timeout [Integer | nil] how long to wait for an event, in milliseconds.
        # @returns [PeekedEvents] the page of events.
        def peek_events(from, room_id: nil, timeout: nil)
          parameters = {from: from, room_id: room_id, timeout: timeout}.compact

          api::PeekedEvents.get(@resource.with(path: "#{V3}/events", parameters: parameters))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
