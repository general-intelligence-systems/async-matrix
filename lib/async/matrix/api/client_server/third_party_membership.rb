# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Inviting someone to a room by an address rather than a user.
      class ThirdPartyMembership
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ThirdPartyMembership] the invitations.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Invite someone to a room by an email address or a phone number.
        #
        # The identity server resolves the address.
        #
        # @parameter room_id [String] the room to invite them to.
        # @parameter id_server [String] the identity server to resolve the address through.
        # @parameter id_access_token [String] the token for that identity server.
        # @parameter medium [String] `email` or `msisdn`.
        # @parameter address [String] the address to invite.
        # @returns [Representation] the empty response.
        def invite_by_3pid(room_id, id_server, id_access_token, medium, address)
          payload = {id_server: id_server, id_access_token: id_access_token, medium: medium, address: address}

          api::Representation.post(@resource.with(path: "#{api::Room.path_for(room_id)}/invite"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
