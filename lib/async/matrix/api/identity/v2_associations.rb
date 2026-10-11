# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module Identity
      # An address a session validated.
      class ValidatedAddress < Representation
        include Versioned

        # @returns [String] `email` or `msisdn`.
        def medium
          self.value[:medium]
        end

        # @returns [String] the address itself.
        def address
          self.value[:address]
        end

        # @returns [Integer] when it was validated, in milliseconds since the epoch.
        def validated_at
          self.value[:validated_at]
        end
      end

      # An address bound to a user, as the server signed it.
      class Association < Representation
        include Versioned

        # @returns [String] the user the address is bound to.
        def mxid
          self.value[:mxid]
        end

        # @returns [String] `email` or `msisdn`.
        def medium
          self.value[:medium]
        end

        # @returns [String] the address itself.
        def address
          self.value[:address]
        end

        # @returns [Hash] the signatures, by server and then by key.
        def signatures
          self.value[:signatures] || {}
        end

        # @returns [Integer] when the association was made, in milliseconds since the epoch.
        def ts
          self.value[:ts]
        end

        # @returns [Integer] when it starts being valid, in milliseconds since the epoch.
        def not_before
          self.value[:not_before]
        end

        # @returns [Integer] when it stops being valid, in milliseconds since the epoch.
        def not_after
          self.value[:not_after]
        end
      end

      # The associations between an address and a user.
      class V2Associations
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2Associations] the associations.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The address a validation session validated.
        #
        # @parameter sid [String] the session.
        # @parameter client_secret [String] the secret the session was opened with.
        # @returns [ValidatedAddress] the address, and when it was validated.
        def get_validated_3pid_v2(sid, client_secret)
          parameters = {sid: sid, client_secret: client_secret}

          api::ValidatedAddress.get(@resource.with(path: "#{IDENTITY_V2}/3pid/getValidated3pid", parameters: parameters))
        end

        # Bind a validated address to a user, which is what makes them findable by it.
        #
        # @parameter sid [String] the session which validated the address.
        # @parameter client_secret [String] the secret the session was opened with.
        # @parameter mxid [String] the user to bind it to.
        # @returns [Association] the association, signed by the server.
        def bind_v2(sid, client_secret, mxid)
          payload = {sid: sid, client_secret: client_secret, mxid: mxid}

          api::Association.post(@resource.with(path: "#{IDENTITY_V2}/3pid/bind"), payload)
        end

        # Remove a binding, which stops the user being findable by the address.
        #
        # The address is proved by a session, or by the homeserver's signature.
        #
        # @parameter mxid [String] the user to unbind from.
        # @parameter threepid [Hash] the address, as `medium` and `address`.
        # @parameter sid [String | nil] the session which validated it.
        # @parameter client_secret [String | nil] the secret that session was opened with.
        # @returns [Representation] the empty response.
        def unbind_v2(mxid, threepid, sid: nil, client_secret: nil)
          payload = {mxid: mxid, threepid: threepid, sid: sid, client_secret: client_secret}.compact

          api::Representation.post(@resource.with(path: "#{IDENTITY_V2}/3pid/unbind"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
