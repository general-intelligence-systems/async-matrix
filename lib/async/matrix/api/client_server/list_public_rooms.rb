# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/list_public_rooms"

module Async
  module Matrix
    module ClientServer
      # A page of the rooms a homeserver publishes.
      class PublicRooms < Representation
        include Versioned

        # @returns [Array(Hash)] the rooms in this page.
        def chunk
          self.value[:chunk] || []
        end

        # @returns [String | nil] the token to ask for the following page from.
        def next_batch
          self.value[:next_batch]
        end

        # @returns [String | nil] the token to ask for the preceding page from.
        def prev_batch
          self.value[:prev_batch]
        end

        # The rooms the homeserver believes it has, which it is allowed to estimate.
        #
        # @returns [Integer | nil] the count.
        def total_room_count_estimate
          self.value[:total_room_count_estimate]
        end

        # @returns [Boolean] whether this page is empty.
        def empty?
          self.chunk.empty?
        end
      end

      # Whether a room is published.
      class RoomVisibility < Representation
        include Versioned

        # @returns [String] `public` or `private`.
        def visibility
          self.value[:visibility]
        end

        # @returns [Boolean] whether the room is in the directory.
        def public?
          self.visibility == "public"
        end
      end

      # The rooms a homeserver publishes.
      class ListPublicRooms
        include Versioned

        # @parameter room_id [String] the room.
        # @returns [String] the path of whether that room is published.
        def self.path_for(room_id)
          "#{V3}/directory/list/room/#{::Protocol::URL::Encoding.escape(room_id)}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ListPublicRooms] the directory.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The rooms a homeserver publishes. No authentication is required.
        #
        # @parameter limit [Integer | nil] the most rooms wanted.
        # @parameter since [String | nil] the token a previous page ended at.
        # @parameter server [String | nil] the homeserver to ask, where it is not this one.
        # @returns [PublicRooms] the page of rooms.
        def get_public_rooms(limit: nil, since: nil, server: nil)
          parameters = {limit: limit, since: since, server: server}.compact

          api::PublicRooms.get(@resource.with(path: "#{V3}/publicRooms", parameters: parameters))
        end

        # The rooms a homeserver publishes, narrowed by a filter.
        #
        # @parameter server [String | nil] the homeserver to ask, where it is not this one.
        # @parameter payload [Hash] the rest the specification allows, e.g. `filter:`, `limit:`.
        # @returns [PublicRooms] the page of rooms.
        def query_public_rooms(server: nil, **payload)
          parameters = {server: server}.compact

          api::PublicRooms.post(@resource.with(path: "#{V3}/publicRooms", parameters: parameters), payload)
        end

        # Whether a room is published. No authentication is required.
        #
        # @parameter room_id [String] the room to ask about.
        # @returns [RoomVisibility] whether it is published.
        def get_room_visibility_on_directory(room_id)
          api::RoomVisibility.get(@resource.with(path: self.class.path_for(room_id)))
        end

        # Publish a room, or take it out of the directory.
        #
        # @parameter room_id [String] the room to publish or unpublish.
        # @parameter visibility [String] `public` or `private`.
        # @returns [Representation] the empty response.
        def set_room_visibility_on_directory(room_id, visibility)
          api::Representation.put(@resource.with(path: self.class.path_for(room_id)), {visibility: visibility})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
