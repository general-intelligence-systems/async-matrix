# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/policy_server"

module Async
  module Matrix
    module ClientServer
      # The keys a policy server signs with.
      #
      # The endpoint arrived in v1.18, so the fields are read by that layer.
      class PolicyKeys < Representation
        include Versioned
      end

      # The policy server a room may be asked to check events with.
      class PolicyServer
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [PolicyServer] the policy.
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
