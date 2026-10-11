# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/account_deactivation"
require_relative "administrative_contact"

module Async
  module Matrix
    module ClientServer
      # Deactivating an account.
      #
      # v1.15 took this from the registration, so it is reached by that layer.
      class AccountDeactivation
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [AccountDeactivation] the deactivation.
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
