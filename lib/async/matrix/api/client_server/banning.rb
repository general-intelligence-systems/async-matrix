# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/banning"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Banning a user from a room, and lifting it.
      class Banning
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Banning] the bans.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Ban a user from a room, which removes them and keeps them out.
        #
        # @parameter room_id [String] the room to act in.
        # @parameter user_id [String] the user to act on.
        # @parameter reason [String | nil] what to record as the reason.
        # @returns [Representation] the empty response.
        def ban(room_id, user_id, reason: nil)
          payload = {user_id: user_id, reason: reason}.compact

          api::Representation.post(@resource.with(path: "#{api::Room.path_for(room_id)}/ban"), payload)
        end

        # Lift a ban, which lets the user join again.
        #
        # @parameter room_id [String] the room to act in.
        # @parameter user_id [String] the user to act on.
        # @parameter reason [String | nil] what to record as the reason.
        # @returns [Representation] the empty response.
        def unban(room_id, user_id, reason: nil)
          payload = {user_id: user_id, reason: reason}.compact

          api::Representation.post(@resource.with(path: "#{api::Room.path_for(room_id)}/unban"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
