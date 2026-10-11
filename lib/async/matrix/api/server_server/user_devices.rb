# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/user_devices"

module Async
  module Matrix
    module ServerServer
      # The devices a user has, as their own server reports them.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class Devices < Representation
        include Versioned
      end

      # The devices a user has logged in from.
      class UserDevices
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [UserDevices] the devices.
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
