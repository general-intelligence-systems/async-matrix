# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/users"

module Async
  module Matrix
    module ClientServer
      # One user the directory answered with.
      class DirectoryUser
        # @parameter value [Hash] the entry as the homeserver sent it.
        def initialize(value)
          @value = value
        end

        # @returns [String] the user.
        def user_id
          @value[:user_id]
        end

        # @returns [String | nil] the name they are shown as, where they have one.
        def display_name
          @value[:display_name]
        end

        # @returns [String | nil] the `mxc://` URI of their avatar, where they have one.
        def avatar_url
          @value[:avatar_url]
        end
      end

      # What a search of the user directory found.
      class DirectoryResults < Representation
        include Versioned

        # The users found, ordered by rank.
        #
        # @returns [Array(DirectoryUser)] the users.
        def results
          (self.value[:results] || []).map{|entry| DirectoryUser.new(entry)}
        end

        # @returns [Boolean] whether the homeserver stopped short of every match.
        def limited?
          self.value[:limited]
        end

        # @returns [Boolean] whether it found nobody.
        def empty?
          self.results.empty?
        end
      end

      # Searches the user directory.
      class Users
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Users] the directory.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Search the directory for a user.
        #
        # The homeserver answers with users this one shares a room with, and whoever else it chooses to list.
        #
        # @parameter search_term [String] what to search for.
        # @parameter limit [Integer | nil] the most results wanted, where fewer than the homeserver would give.
        # @returns [DirectoryResults] what it found.
        def search_user_directory(search_term, limit: nil)
          payload = {search_term: search_term, limit: limit}.compact

          api::DirectoryResults.post(@resource.with(path: "#{V3}/user_directory/search"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
