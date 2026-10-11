# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/inviting"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Inviting a user to a room.
      class Inviting
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Inviting] the invitations.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Invite a user to a room.
        #
        # @parameter room_id [String] the room to invite them to.
        # @parameter user_id [String] the user to invite.
        # @parameter reason [String | nil] what to record as the reason.
        # @returns [Representation] the empty response.
        def invite_user(room_id, user_id, reason: nil)
          payload = {user_id: user_id, reason: reason}.compact

          api::Representation.post(@resource.with(path: "#{api::Room.path_for(room_id)}/invite"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
