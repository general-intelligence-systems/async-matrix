# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/application_service/query_room"

module Async
  module Matrix
    module ApplicationService
      # Asking an application service whether a room alias is one of its own.
      class QueryRoom
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [QueryRoom] the query.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Ask whether the service has a room alias.
        #
        # @parameter room_alias [String] the alias to ask about.
        # @returns [Representation] the empty response.
        def query_room_by_alias(room_alias)
          path = "#{APP_V1}/rooms/#{::Protocol::URL::Encoding.escape(room_alias)}"

          api::Representation.get(@resource.with(path: path))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
