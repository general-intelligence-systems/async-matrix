# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Where an alias points.
      class AliasTarget < Representation
        include Versioned

        # @returns [String] the room the alias names.
        def room_id
          self.value[:room_id]
        end

        # @returns [Array(String)] the servers which know the room, best first.
        def servers
          self.value[:servers] || []
        end
      end

      # The aliases a homeserver has for a room.
      class LocalAliases < Representation
        include Versioned

        # @returns [Array(String)] the aliases.
        def aliases
          self.value[:aliases] || []
        end

        # @returns [Boolean] whether the room has none.
        def empty?
          self.aliases.empty?
        end
      end

      # Room aliases, which name a room readably.
      class Directory
        include Versioned

        # @parameter room_alias [String] the alias, e.g. `#room:localhost`.
        # @returns [String] the path of that alias.
        def self.path_for(room_alias)
          "#{V3}/directory/room/#{::Protocol::URL::Encoding.escape(room_alias)}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Directory] the aliases.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The room an alias names. No authentication is required.
        #
        # @parameter room_alias [String] the alias to resolve.
        # @returns [AliasTarget] the room, and where to find it.
        def get_room_id_by_alias(room_alias)
          api::AliasTarget.get(@resource.with(path: self.class.path_for(room_alias)))
        end

        # Point an alias at a room.
        #
        # @parameter room_alias [String] the alias to create.
        # @parameter room_id [String] the room to point it at.
        # @returns [Representation] the empty response.
        def set_room_alias(room_alias, room_id)
          api::Representation.put(@resource.with(path: self.class.path_for(room_alias)), {room_id: room_id})
        end

        # Remove an alias, which leaves the room itself alone.
        #
        # @parameter room_alias [String] the alias to remove.
        # @returns [Representation] the empty response.
        def delete_room_alias(room_alias)
          api::Representation.delete(@resource.with(path: self.class.path_for(room_alias)))
        end

        # The aliases this homeserver has for a room.
        #
        # @parameter room_id [String] the room to ask about.
        # @returns [LocalAliases] the aliases.
        def get_local_aliases(room_id)
          api::LocalAliases.get(@resource.with(path: "#{api::Room.path_for(room_id)}/aliases"))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
