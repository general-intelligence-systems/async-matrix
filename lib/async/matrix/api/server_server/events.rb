# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/events"

module Async
  module Matrix
    module ServerServer
      # Events as one server sends them to another.
      #
      # The specification calls a room event a PDU, and sends them in a transaction.
      class EventTransaction < Representation
        include Versioned
      end

      # The state of a room at an event, as whole events.
      class RoomState < Representation
        include Versioned
      end

      # The state of a room at an event, as IDs.
      class RoomStateIds < Representation
        include Versioned
      end

      # The event nearest a time.
      #
      # The endpoint arrived in v1.6, so the fields are read by that layer.
      class EventAtTimestamp < Representation
        include Versioned
      end

      # The events of a room, and the state around them.
      class Events
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Events] the events.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
