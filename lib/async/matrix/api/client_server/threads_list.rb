# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/threads_list"

module Async
  module Matrix
    module ClientServer
      # A page of the events which start threads.
      #
      # The endpoint arrived in v1.4, so the fields are read by that layer.
      class ThreadRoots < Representation
        include Versioned
      end

      # The threads of a room.
      class ThreadsList
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ThreadsList] the threads.
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
