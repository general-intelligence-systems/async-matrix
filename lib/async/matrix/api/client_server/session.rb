# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/session"

module Async
  module Matrix
    module ClientServer
      # The response to logging in.
      class Login < Representation
        include Versioned

        # @returns [String] the access token to authenticate subsequent requests with.
        def access_token
          self.value[:access_token]
        end

        # @returns [String] the fully qualified ID of the user that logged in.
        def user_id
          self.value[:user_id]
        end

        # @returns [String] the ID of the device that was created by this login.
        def device_id
          self.value[:device_id]
        end
      end

      # The ways a homeserver will let a user log in.
      class LoginFlows < Representation
        include Versioned

        # @returns [Array(Hash)] the supported login flows.
        def flows
          self.value[:flows]
        end

        # @returns [Array(String)] the type of each supported flow, e.g. `m.login.password`.
        def types
          self.flows.map{|flow| flow[:type]}
        end

        # @parameter type [String] the flow type to look for.
        # @returns [Boolean] whether the homeserver supports that flow.
        def supports?(type)
          self.types.include?(type)
        end
      end

      # The identity associated with an access token.
      class Whoami < Representation
        include Versioned

        # @returns [String] the fully qualified ID of the authenticated user.
        def user_id
          self.value[:user_id]
        end

        # @returns [String | nil] the ID of the authenticated device.
        def device_id
          self.value[:device_id]
        end

        # Whether the authenticated user is a guest.
        #
        # `is_guest` arrived in v1.2, whose layer reads it.
        #
        # @returns [Boolean] whether the authenticated user is a guest.
        def guest?
          false
        end
      end
    end
  end
end
