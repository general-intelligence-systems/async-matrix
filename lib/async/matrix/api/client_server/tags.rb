# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/tags"

module Async
  module Matrix
    module ClientServer
      # The tags on one room.
      class RoomTags < Representation
        include Versioned

        # @returns [Hash] the tags, by name, each carrying the order the user gave it.
        def tags
          self.value[:tags] || {}
        end

        # @returns [Array(Symbol)] the names of the tags.
        def names
          self.tags.keys
        end

        # @returns [Boolean] whether the room has none.
        def empty?
          self.tags.empty?
        end
      end

      # The tags a user has put on their rooms.
      class Tags
        include Versioned

        # @parameter user_id [String] the user whose tags they are.
        # @parameter room_id [String] the room they are on.
        # @returns [String] the path of the tags on that room.
        def self.path_for(user_id, room_id)
          "#{V3}/user/#{::Protocol::URL::Encoding.escape(user_id)}/rooms/#{::Protocol::URL::Encoding.escape(room_id)}/tags"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Tags] the tags.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The tags this user has put on a room.
        #
        # @parameter user_id [String] the user whose tags they are.
        # @parameter room_id [String] the room to read them for.
        # @returns [RoomTags] the tags.
        def get_room_tags(user_id, room_id)
          api::RoomTags.get(@resource.with(path: self.class.path_for(user_id, room_id)))
        end

        # Put a tag on a room.
        #
        # @parameter user_id [String] the user whose tag it is.
        # @parameter room_id [String] the room to tag.
        # @parameter tag [String] the tag, e.g. `m.favourite`.
        # @parameter order [Float | nil] where the room sorts among the others with this tag.
        # @returns [Representation] the empty response.
        def set_room_tag(user_id, room_id, tag, order: nil)
          payload = {order: order}.compact
          path = "#{self.class.path_for(user_id, room_id)}/#{::Protocol::URL::Encoding.escape(tag)}"

          api::Representation.put(@resource.with(path: path), payload)
        end

        # Take a tag off a room.
        #
        # @parameter user_id [String] the user whose tag it is.
        # @parameter room_id [String] the room to untag.
        # @parameter tag [String] the tag to remove.
        # @returns [Representation] the empty response.
        def delete_room_tag(user_id, room_id, tag)
          path = "#{self.class.path_for(user_id, room_id)}/#{::Protocol::URL::Encoding.escape(tag)}"

          api::Representation.delete(@resource.with(path: path))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
