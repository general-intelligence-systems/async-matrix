# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/refresh"

module Async
  module Matrix
    module ClientServer
      # The tokens a refresh issued.
      #
      # The endpoint arrived in v1.3, so the fields are read by that layer.
      class Refreshed < Representation
        include Versioned
      end

      # Exchanges a refresh token for a new access token.
      #
      # The resource must be unauthenticated: a client which renewed through itself would recurse.
      class Refresh
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Refresh] the refresh.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Nothing to revoke: a session the homeserver issued is ended by logging out.
        #
        # @parameter token [String] the token which would be withdrawn.
        # @parameter token_type_hint [String | nil] what kind of token it is.
        # @returns [Nil] nothing.
        def revoke(token, token_type_hint: nil)
        end

        # Nothing to close: this shares the client's delegate, which the client still needs.
        #
        # @returns [Nil] nothing.
        def close
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
