# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/filter"

module Async
  module Matrix
    module ClientServer
      # The filter a definition created.
      class FilterReference < Representation
        include Versioned

        # @returns [String] the ID to quote when syncing.
        def filter_id
          self.value[:filter_id]
        end
      end

      # A filter as the homeserver stored it.
      class FilterDefinition < Representation
        include Versioned

        # @returns [Hash] what it says about the events of a room.
        def room
          self.value[:room] || {}
        end

        # @returns [Hash] what it says about presence.
        def presence
          self.value[:presence] || {}
        end

        # @returns [Hash] what it says about account data.
        def account_data
          self.value[:account_data] || {}
        end

        # @returns [Array(String) | nil] the event fields it keeps, where it names them.
        def event_fields
          self.value[:event_fields]
        end

        # @returns [String | nil] the format the events come in, where it asked for one.
        def event_format
          self.value[:event_format]
        end
      end

      # The filters a user has defined, which narrow what a sync returns.
      class Filter
        include Versioned

        # @parameter user_id [String] the user whose filters they are.
        # @returns [String] the path of that user's filters.
        def self.path_for(user_id)
          "#{V3}/user/#{::Protocol::URL::Encoding.escape(user_id)}/filter"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Filter] the filters.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Define a filter, which the homeserver keeps so that a sync can name it.
        #
        # @parameter user_id [String] the user to define it for.
        # @parameter definition [Hash] the filter, e.g. `room:`, `presence:`, `event_fields:`.
        # @returns [FilterReference] the filter, by ID.
        def define_filter(user_id, definition)
          api::FilterReference.post(@resource.with(path: self.class.path_for(user_id)), definition)
        end

        # A filter the homeserver is keeping.
        #
        # @parameter user_id [String] the user whose filter it is.
        # @parameter filter_id [String] the filter to read.
        # @returns [FilterDefinition] the filter as it was defined.
        def get_filter(user_id, filter_id)
          path = "#{self.class.path_for(user_id)}/#{::Protocol::URL::Encoding.escape(filter_id)}"

          api::FilterDefinition.get(@resource.with(path: path))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
