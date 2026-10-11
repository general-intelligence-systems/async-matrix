# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/oauth_server_metadata"

module Async
  module Matrix
    module ClientServer
      # Where the authorization server is, and what it supports.
      #
      # The endpoint arrived in v1.15, so the fields are read by that layer.
      class AuthMetadata < Representation
        include Versioned
      end

      # Where the homeserver's OAuth endpoints are.
      class OAuthServerMetadata
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [OAuthServerMetadata] the metadata.
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
