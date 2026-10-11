# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/invites_v1"

module Async
  module Matrix
    module ServerServer
      # The invite both servers signed, wrapped in a status.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class InvitedEventV1 < Representation
        include Versioned
      end

      # Inviting a user, as the first version of the endpoint had it.
      class InvitesV1
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [InvitesV1] the invite.
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
