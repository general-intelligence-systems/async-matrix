# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # The tokens a refresh issued.
      class Refreshed < Representation
        include Versioned

        # @returns [String] the access token to authenticate with from now on.
        def access_token
          self.value[:access_token]
        end

        # @returns [String | nil] the token for the next refresh, if the homeserver rotated it.
        def refresh_token
          self.value[:refresh_token]
        end

        # @returns [Integer | nil] how long the new access token lasts, in milliseconds.
        def expires_in_ms
          self.value[:expires_in_ms]
        end
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

        def inspect
          "\#<#{self.class}>"
        end

        # Exchange a refresh token for a new access token.
        #
        # @parameter refresh_token [String] the refresh token to exchange.
        # @returns [Refreshed] the tokens the homeserver issued.
        def refresh(refresh_token)
          api::Refreshed.post(@resource.with(path: "#{V3}/refresh"), {refresh_token: refresh_token})
        end
      end
    end
  end
end
