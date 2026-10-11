# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # The rules which decide what raises a notification.
      #
      # The operations are not written yet: this is the class `pushrules-v1.19.yaml` names.
      class PushRules
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [PushRules] the rules.
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
