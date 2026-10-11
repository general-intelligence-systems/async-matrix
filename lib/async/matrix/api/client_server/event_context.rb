# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/event_context"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # What was happening around an event.
      class SurroundingEvents < Representation
        include Versioned

        # @returns [Hash] the event asked about.
        def event
          self.value[:event]
        end

        # @returns [Array(Hash)] the events before it, nearest first.
        def events_before
          self.value[:events_before] || []
        end

        # @returns [Array(Hash)] the events after it, nearest first.
        def events_after
          self.value[:events_after] || []
        end

        # @returns [Array(Hash)] the state of the room at the end of this context.
        def state
          self.value[:state] || []
        end

        # @returns [String | nil] the token for paging backwards from here.
        def start
          self.value[:start]
        end

        # @returns [String | nil] the token for paging forwards from here.
        def finish
          self.value[:end]
        end
      end

      # The events around an event.
      class EventContext
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [EventContext] the context.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The events either side of an event.
        #
        # @parameter room_id [String] the room the event is in.
        # @parameter event_id [String] the event to look around.
        # @parameter limit [Integer | nil] the most events wanted either side.
        # @parameter filter [String | nil] a filter, as JSON, to narrow which events count.
        # @returns [SurroundingEvents] what was happening around it.
        def get_event_context(room_id, event_id, limit: nil, filter: nil)
          parameters = {limit: limit, filter: filter}.compact
          path = "#{api::Room.path_for(room_id)}/context/#{::Protocol::URL::Encoding.escape(event_id)}"

          api::SurroundingEvents.get(@resource.with(path: path, parameters: parameters))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
