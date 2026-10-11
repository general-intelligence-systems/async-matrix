# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/user_keys"

module Async
  module Matrix
    module ServerServer
      # The encryption keys of a user's devices.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class DeviceKeys < Representation
        include Versioned
      end

      # The one time keys a server handed over.
      class ClaimedKeys < Representation
        include Versioned
      end

      # The end to end encryption keys of a user.
      class UserKeys
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [UserKeys] the keys.
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
