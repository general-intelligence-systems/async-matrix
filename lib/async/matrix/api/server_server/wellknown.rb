# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/wellknown"

module Async
  module Matrix
    module ServerServer
      # Where a server says it is to be reached.
      #
      # The document arrived in v1.1, so the fields are read by that layer.
      class ServerDiscovery < Representation
        include Versioned
      end

      # Where a server should look for another.
      class Wellknown
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Wellknown] the discovery document.
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
