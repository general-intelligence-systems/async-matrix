# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/room_initial_sync"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Everything the homeserver will say about one room at once.
      class RoomSnapshot < Representation
        include Versioned

        # @returns [String] the room this describes.
        def room_id
          self.value[:room_id]
        end

        # @returns [String] this user's membership of it, e.g. `join`.
        def membership
          self.value[:membership]
        end

        # @returns [Hash] the recent events, as a page.
        def messages
          self.value[:messages] || {}
        end

        # @returns [Array(Hash)] the state of the room.
        def state
          self.value[:state] || []
        end

        # @returns [String | nil] whether the room is published in the directory.
        def visibility
          self.value[:visibility]
        end

        # @returns [Array(Hash)] this user's account data for the room.
        def account_data
          self.value[:account_data] || []
        end
      end

      # A room's state and recent events in one request.
      class RoomInitialSync
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [RoomInitialSync] the sync.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # A room's state and recent events together.
        #
        # @parameter room_id [String] the room to ask about.
        # @returns [RoomSnapshot] what the homeserver says about it.
        def room_initial_sync(room_id)
          api::RoomSnapshot.get(@resource.with(path: "#{api::Room.path_for(room_id)}/initialSync"))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
