# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require "async/rest/representation"

require_relative "../../paths"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/content_repository"
require_relative "../../wrapper/multipart"

module Async
  module Matrix
    module ServerServer
      # A file another server holds, and what it says about it.
      #
      # The endpoint arrived in v1.11, so the fields are read by that layer.
      class FederatedContent < Async::REST::Representation[Wrapper::Multipart]
        include Versioned
      end

      # The files another server holds.
      class ContentRepository
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ContentRepository] the repository.
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
