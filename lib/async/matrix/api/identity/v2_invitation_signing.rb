# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/identity/v2_invitation_signing"

module Async
  module Matrix
    module Identity
      # An invitation, signed for the user who claimed it.
      class SignedInvitation < Representation
        include Versioned

        # @returns [String] the user who was signed in.
        def mxid
          self.value[:mxid]
        end

        # @returns [String] the user who sent the invitation.
        def sender
          self.value[:sender]
        end

        # @returns [String] the token which was signed.
        def token
          self.value[:token]
        end

        # @returns [Hash] the signatures, by server and then by key.
        def signatures
          self.value[:signatures] || {}
        end
      end

      # Signing an invitation which was sent to an address.
      class V2InvitationSigning
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2InvitationSigning] the signing.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Sign a user into an invitation which was sent to an address.
        #
        # The key is the one the invitation carried.
        #
        # @parameter mxid [String] the user to sign in.
        # @parameter token [String] the token the invitation carried.
        # @parameter private_key [String] the key the invitation carried, unpadded base64.
        # @returns [SignedInvitation] the invitation, signed.
        def blindly_sign_stuff_v2(mxid, token, private_key)
          payload = {mxid: mxid, token: token, private_key: private_key}

          api::SignedInvitation.post(@resource.with(path: "#{IDENTITY_V2}/sign-ed25519"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
