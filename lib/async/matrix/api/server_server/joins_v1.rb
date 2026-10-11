# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../removals"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/joins_v1"
require_relative "parameters"

module Async
  module Matrix
    module ServerServer
      # An event a server built for another to sign.
      #
      # A join, a leave and a knock are all answered this way, so all three read it.
      class MembershipTemplate < Representation
        include Versioned
      end

      # The state of a room at a join, wrapped in a status.
      #
      # The first version of the endpoint answered `[200, {...}]`, which v2 dropped.
      class JoinedRoomV1 < Representation
        include Versioned
      end

      # Joining a room, as the first version of the endpoints had it.
      class JoinsV1
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [JoinsV1] the join.
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
