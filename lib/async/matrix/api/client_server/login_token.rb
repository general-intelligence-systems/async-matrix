# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/login_token"

module Async
  module Matrix
    module ClientServer
      # The single use token a homeserver generated.
      #
      # The endpoint arrived in v1.7, so the fields are read by that layer.
      class GeneratedLoginToken < Representation
        include Versioned
      end

      # Issues a single use token for logging in elsewhere.
      class LoginToken
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [LoginToken] the tokens.
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
