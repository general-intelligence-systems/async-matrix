# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/support"

module Async
  module Matrix
    module ClientServer
      # The contacts a homeserver publishes.
      #
      # The endpoint arrived in v1.10, so the fields are read by that layer.
      class SupportContacts < Representation
        include Versioned
      end

      # Who to contact about a homeserver.
      class Support
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Support] the contacts.
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
