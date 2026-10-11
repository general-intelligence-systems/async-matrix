# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../removals"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/knocks"
require_relative "joins_v1"
require_relative "parameters"

module Async
  module Matrix
    module ServerServer
      # What a room will say about itself to somebody knocking on it.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class KnockedRoom < Representation
        include Versioned
      end

      # Knocking on a room, which is asking to be let in.
      class Knocks
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Knocks] the membership change.
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
