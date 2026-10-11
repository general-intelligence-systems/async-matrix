# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/openid"

module Async
  module Matrix
    module ClientServer
      # A token another service can check with the homeserver.
      class OpenIDToken < Representation
        include Versioned

        # @returns [String] the token to give to the service.
        def access_token
          self.value[:access_token]
        end

        # @returns [String] the kind of token it is, which is `Bearer`.
        def token_type
          self.value[:token_type]
        end

        # @returns [String] the homeserver the service should check it with.
        def matrix_server_name
          self.value[:matrix_server_name]
        end

        # @returns [Integer] how long the token lasts, in seconds.
        def expires_in
          self.value[:expires_in]
        end
      end

      # A token which proves to another service who this user is.
      class OpenID
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [OpenID] the tokens.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Ask for a token which proves to another service who this user is.
        #
        # @parameter user_id [String] the user to prove.
        # @returns [OpenIDToken] the token, and where to check it.
        def request_open_id_token(user_id)
          path = "#{V3}/user/#{::Protocol::URL::Encoding.escape(user_id)}/openid/request_token"

          api::OpenIDToken.post(@resource.with(path: path), {})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
