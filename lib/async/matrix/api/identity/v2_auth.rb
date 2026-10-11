# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module Identity
      # The token a registration issued.
      class AccessToken < Representation
        include Versioned

        # @returns [String] the token to talk to the identity server with.
        def token
          self.value[:token]
        end
      end

      # Who a token belongs to.
      class Account < Representation
        include Versioned

        # @returns [String] the user the token was issued for.
        def user_id
          self.value[:user_id]
        end
      end

      # The token an identity server is talked to with.
      class V2Auth
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2Auth] the account.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Exchange an OpenID token from a homeserver for one of this server's own.
        #
        # No authentication is required: the OpenID token vouches for the user.
        #
        # @parameter access_token [String] the OpenID token the homeserver issued.
        # @parameter token_type [String] the kind of token it is, which is `Bearer`.
        # @parameter matrix_server_name [String] the homeserver which issued it.
        # @parameter expires_in [Integer] how long it lasts, in seconds.
        # @returns [AccessToken] the token to talk to this server with.
        def register_account(access_token, token_type, matrix_server_name, expires_in)
          payload = {access_token: access_token, token_type: token_type, matrix_server_name: matrix_server_name, expires_in: expires_in}

          api::AccessToken.post(@resource.with(path: "#{IDENTITY_V2}/account/register"), payload)
        end

        # Who the token belongs to.
        #
        # @returns [Account] the user.
        def get_account
          api::Account.get(@resource.with(path: "#{IDENTITY_V2}/account"))
        end

        # Invalidate the token.
        #
        # @returns [Representation] the empty response.
        def logout
          api::Representation.post(@resource.with(path: "#{IDENTITY_V2}/account/logout"), {})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
