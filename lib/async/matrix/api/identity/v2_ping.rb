# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/identity/v2_ping"

module Async
  module Matrix
    module Identity
      # Whether an identity server is there.
      class V2Ping
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2Ping] the ping.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Whether the server is ready to answer. No authentication is required.
        #
        # @returns [Representation] the empty response.
        def ping_v2
          api::Representation.get(@resource.with(path: IDENTITY_V2))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
