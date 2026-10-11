# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/identity/v2_store_invite"

module Async
  module Matrix
    module Identity
      # An invitation the server is holding.
      class StoredInvite < Representation
        include Versioned

        # @returns [String] the token which claims the invitation.
        def token
          self.value[:token]
        end

        # @returns [Array(Hash)] the keys the invitation may be signed with.
        def public_keys
          self.value[:public_keys] || []
        end

        # @returns [String] the address, as the server will show it to the room.
        def display_name
          self.value[:display_name]
        end
      end

      # Inviting someone who has no account yet.
      class V2StoreInvite
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2StoreInvite] the invitations.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Ask the server to hold an invitation for an address, and to tell whoever claims it.
        #
        # @parameter medium [String] `email` or `msisdn`.
        # @parameter address [String] the address to invite.
        # @parameter room_id [String] the room they are invited to.
        # @parameter sender [String] the user inviting them.
        # @parameter options [Hash] what to show them, e.g. `room_name:`, `sender_display_name:`.
        # @returns [StoredInvite] the token, and the keys which sign it.
        def store_invite_v2(medium, address, room_id, sender, **options)
          payload = {medium: medium, address: address, room_id: room_id, sender: sender, **options}

          api::StoredInvite.post(@resource.with(path: "#{IDENTITY_V2}/store-invite"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
