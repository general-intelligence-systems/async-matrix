# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../removals"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/leaving_v1"
require_relative "joins_v1"
require_relative "parameters"

module Async
  module Matrix
    module ServerServer
      # Leaving a room, as the first version of the endpoints had it.
      class LeavingV1
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [LeavingV1] the membership change.
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
