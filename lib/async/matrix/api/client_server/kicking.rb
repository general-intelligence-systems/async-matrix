# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/kicking"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Removing a user from a room.
      class Kicking
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Kicking] the kicks.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Remove a user from a room, which they may join again.
        #
        # @parameter room_id [String] the room to act in.
        # @parameter user_id [String] the user to act on.
        # @parameter reason [String | nil] what to record as the reason.
        # @returns [Representation] the empty response.
        def kick(room_id, user_id, reason: nil)
          payload = {user_id: user_id, reason: reason}.compact

          api::Representation.post(@resource.with(path: "#{api::Room.path_for(room_id)}/kick"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
