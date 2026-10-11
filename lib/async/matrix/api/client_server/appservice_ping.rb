# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/appservice_ping"

module Async
  module Matrix
    module ClientServer
      # How long a ping took.
      #
      # The endpoint arrived in v1.7, so the fields are read by that layer.
      class Ping < Representation
        include Versioned
      end

      # Pinging an application service.
      class AppservicePing
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [AppservicePing] the ping.
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
