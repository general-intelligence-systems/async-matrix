# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # The rooms a space contains, and their spaces.
      #
      # The operations are not written yet: this is the class `space_hierarchy-v1.19.yaml` names.
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
