# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/password_management"
require_relative "administrative_contact"

module Async
  module Matrix
    module ClientServer
      # Changing a password, and asking for the tokens a reset needs.
      #
      # v1.15 took these from the registration, so they are reached by that layer.
      class PasswordManagement
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [PasswordManagement] the passwords.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
