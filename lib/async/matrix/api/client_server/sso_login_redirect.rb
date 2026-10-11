# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/sso_login_redirect"

module Async
  module Matrix
    module ClientServer
      # Sends the user to a single sign on provider.
      #
      # These endpoints answer with a redirect for the user's browser to follow, so they are built rather than requested.
      class SSOLoginRedirect
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [SSOLoginRedirect] the redirect.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The absolute URL of a path on this homeserver.
        #
        # The user's browser follows it, so it cannot be relative.
        #
        # @parameter path [String] the path on the homeserver.
        # @parameter parameters [Hash] the query parameters, of which the nil ones are dropped.
        # @returns [String] the URL.
        def url_for(path, **parameters)
          reference = @resource.reference.with(path: path, parameters: parameters.compact)
          endpoint = self.homeserver

          "#{endpoint.scheme}://#{endpoint.authority}#{reference}"
        end

        def inspect
          "\#<#{self.class}>"
        end

        # The endpoint at the bottom of the resource's delegate chain.
        #
        # @returns [Async::HTTP::Endpoint] where the homeserver is.
        private def homeserver
          delegate = @resource

          while delegate.respond_to?(:delegate) and delegate.delegate
            delegate = delegate.delegate
          end

          delegate.endpoint
        end
      end
    end
  end
end
