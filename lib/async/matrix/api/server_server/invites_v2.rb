# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/invites_v2"

module Async
  module Matrix
    module ServerServer
      # The invite both servers signed.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class InvitedEvent < Representation
        include Versioned
      end

      # Inviting a user through the server which owns them.
      class InvitesV2
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [InvitesV2] the invite.
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
