# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "rooms"
require_relative "../../abstract/api/client_server/room_upgrades"

module Async
  module Matrix
    module ClientServer
      # The room an upgrade created.
      class UpgradedRoom < Representation
        include Versioned

        # @returns [String] the room which replaces the one upgraded.
        def replacement_room
          self.value[:replacement_room]
        end
      end

      # Upgrading a room to another room version.
      class RoomUpgrades
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [RoomUpgrades] the upgrades.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Upgrade a room, which replaces it with a new room at a later room version.
        #
        # @parameter room_id [String] the room to upgrade.
        # @parameter new_version [String] the room version to upgrade to.
        # @parameter payload [Hash] the rest the specification allows, e.g. `additional_creators:`.
        # @returns [UpgradedRoom] the room which replaced it.
        def upgrade_room(room_id, new_version, **payload)
          api::UpgradedRoom.post(@resource.with(path: "#{api::Room.path_for(room_id)}/upgrade"), {new_version: new_version, **payload})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
