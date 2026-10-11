# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/identity/v2_terms"

module Async
  module Matrix
    module Identity
      # The policies an identity server has.
      class Policies < Representation
        include Versioned

        # @returns [Hash] the policies, by name, each carrying a version per language.
        def policies
          self.value[:policies] || {}
        end

        # @returns [Array(Symbol)] the names of the policies.
        def names
          self.policies.keys
        end
      end

      # The policies an identity server asks a user to accept.
      class V2Terms
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2Terms] the terms.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The policies the server has. No authentication is required.
        #
        # @returns [Policies] the policies, by name.
        def get_terms
          api::Policies.get(@resource.with(path: "#{IDENTITY_V2}/terms"))
        end

        # Accept policies on this user's behalf.
        #
        # @parameter user_accepts [Array(String)] the URLs of the versions accepted.
        # @returns [Representation] the empty response.
        def agree_to_terms(user_accepts)
          api::Representation.post(@resource.with(path: "#{IDENTITY_V2}/terms"), {user_accepts: user_accepts})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
