# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/versions"

module Async
  module Matrix
    module ClientServer
      # What a homeserver says it implements.
      #
      # Deliberately not `Versions`, which must keep resolving to {Async::Matrix::Versions} inside `ClientServer`.
      class ServerVersions < Representation
        include Versioned

        # @returns [Array(String)] the specification versions, e.g. `v1.17`.
        def versions
          self.value[:versions] || []
        end

        # @returns [Hash] the unstable features it has, by name.
        def unstable_features
          self.value[:unstable_features] || {}
        end

        # @parameter version [String] a specification version.
        # @returns [Boolean] whether the homeserver implements it.
        def supports?(version)
          self.versions.include?(version)
        end
      end

      # The specification versions this homeserver implements.
      #
      # Deliberately not `Versions`, which must keep resolving to {Async::Matrix::Versions} inside `ClientServer`.
      class SupportedVersions
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [SupportedVersions] the versions.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The specification versions this homeserver implements.
        #
        # The path carries no version of its own.
        #
        # @returns [ServerVersions] what it implements.
        def get_versions
          api::ServerVersions.get(@resource.with(path: "/_matrix/client/versions"))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
