# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/application_service/ping"

module Async
  module Matrix
    module ApplicationService
      # Whether an application service is answering.
      #
      # The endpoint arrived in v1.7, so the operation is answered by that layer.
      class Ping
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Ping] the ping.
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
