# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/room_summary"

module Async
  module Matrix
    module ClientServer
      # A room as a homeserver summarises it.
      #
      # The endpoint arrived in v1.15, so the fields are read by that layer.
      class SummarisedRoom < Representation
        include Versioned
      end

      # What a homeserver will say about a room without joining it.
      class RoomSummary
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [RoomSummary] the summary.
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
