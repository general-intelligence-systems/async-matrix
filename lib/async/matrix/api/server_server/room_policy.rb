# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/room_policy"

module Async
  module Matrix
    module ServerServer
      # An event a policy server recommended for a room.
      #
      # The endpoint arrived in v1.18, so the fields are read by that layer.
      class SignedEvent < Representation
        include Versioned
      end

      # The policy server a room checks its events with.
      class RoomPolicy
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [RoomPolicy] the policy server.
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
