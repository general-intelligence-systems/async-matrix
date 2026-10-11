# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/joins_v2"
require_relative "joins_v1"

module Async
  module Matrix
    module ServerServer
      # The state of a room at a join.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class JoinedRoom < Representation
        include Versioned
      end

      # Joining a room, which the template comes from {JoinsV1}.
      class JoinsV2
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [JoinsV2] the join.
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
