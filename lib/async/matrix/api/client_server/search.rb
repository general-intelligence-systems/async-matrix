# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/search"

module Async
  module Matrix
    module ClientServer
      # What a search found.
      class SearchResults < Representation
        include Versioned

        # The results, by the category they were asked for, which is `room_events`.
        #
        # @returns [Hash] the categories.
        def search_categories
          self.value[:search_categories] || {}
        end

        # @returns [Array(Hash)] the events found, each with its rank and its context.
        def results
          self.search_categories.dig(:room_events, :results) || []
        end

        # @returns [Integer | nil] how many matched, which may be more than were returned.
        def count
          self.search_categories.dig(:room_events, :count)
        end

        # @returns [Boolean] whether it found nothing.
        def empty?
          self.results.empty?
        end
      end

      # Searching the events of the rooms a user is in.
      class Search
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Search] the search.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Search the events of the rooms this user is in.
        #
        # @parameter search_categories [Hash] what to search for, e.g. `room_events:`.
        # @parameter next_batch [String | nil] the token a previous page ended at.
        # @returns [SearchResults] what it found.
        def search(search_categories, next_batch: nil)
          parameters = {next_batch: next_batch}.compact

          api::SearchResults.post(@resource.with(path: "#{V3}/search", parameters: parameters), {search_categories: search_categories})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
