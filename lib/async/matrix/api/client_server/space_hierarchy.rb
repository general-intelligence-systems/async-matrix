# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/space_hierarchy"

module Async
  module Matrix
    module ClientServer
      # A page of the rooms a space holds.
      #
      # The endpoint arrived in v1.2, so the fields are read by that layer.
      class Hierarchy < Representation
        include Versioned
      end

      # The rooms a space holds.
      class SpaceHierarchy
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [SpaceHierarchy] the hierarchy.
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
