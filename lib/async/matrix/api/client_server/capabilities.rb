# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/capabilities"

module Async
  module Matrix
    module ClientServer
      # What the homeserver will let this user do.
      #
      # A named capability is read by the version which describes it, so those readers are layered.
      class Capabilities < Representation
        include Versioned

        # @returns [Hash] every capability the homeserver advertised, by name.
        def capabilities
          self.value[:capabilities] || {}
        end

        # @parameter name [String] the capability, e.g. `m.change_password`.
        # @returns [Hash | nil] what the homeserver said about it, or nil.
        def [](name)
          self.capabilities[name.to_sym]
        end

        # Whether the homeserver advertised a capability at all.
        #
        # @parameter name [String] the capability.
        # @returns [Boolean] whether it was advertised.
        def advertised?(name)
          self.capabilities.key?(name.to_sym)
        end

        # Whether a capability is enabled, which is not the same question as whether it was advertised.
        #
        # @parameter name [String] the capability.
        # @returns [Boolean | nil] whether it is enabled, or nil if it was not advertised.
        def enabled?(name)
          self[name]&.fetch(:enabled, nil)
        end
      end
    end
  end
end
