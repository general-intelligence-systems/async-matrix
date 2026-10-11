# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../content"
require_relative "../../paths"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/authed_content_repo"
require_relative "content_repo"

module Async
  module Matrix
    module ClientServer
      # The files a homeserver holds, asked for with an access token.
      class AuthedContentRepo
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [AuthedContentRepo] the repository.
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
