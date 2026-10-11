# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/application_service/query_user"

module Async
  module Matrix
    module ApplicationService
      # Asking an application service whether a user is one of its own.
      class QueryUser
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [QueryUser] the query.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Ask whether the service has a user.
        #
        # A service which does creates it and answers; one which does not answers that it has nobody.
        #
        # @parameter user_id [String] the user to ask about.
        # @returns [Representation] the empty response.
        def query_user_by_id(user_id)
          path = "#{APP_V1}/users/#{::Protocol::URL::Encoding.escape(user_id)}"

          api::Representation.get(@resource.with(path: path))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
