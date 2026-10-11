# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # Invites someone by email or telephone number.
      #
      # The operations are not written yet: this is the class `third_party_membership-v1.19.yaml` names.
      class ThirdPartyMembership
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ThirdPartyMembership] the invitations.
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
