# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/keys_server"

module Async
  module Matrix
    module ServerServer
      # The keys a server publishes for itself.
      #
      # The document arrived in v1.1, so the fields are read by that layer.
      class PublishedKeys < Representation
        include Versioned
      end

      # The keys a server signs with.
      class KeysServer
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [KeysServer] the keys.
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
