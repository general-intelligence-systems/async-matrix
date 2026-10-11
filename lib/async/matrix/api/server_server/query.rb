# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/query"

module Async
  module Matrix
    module ServerServer
      # A user's profile, as the server which owns them reports it.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class Profile < Representation
        include Versioned
      end

      # The room an alias names, and who to ask about it.
      class RoomDirectoryEntry < Representation
        include Versioned
      end

      # The answer to a query of a kind the specification does not name.
      class QueryResult < Representation
        include Versioned
      end

      # What another server will tell us about a user or an alias.
      class Query
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Query] the queries.
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
