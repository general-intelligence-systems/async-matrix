# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module Identity
      # What an identity server says it implements.
      #
      # Deliberately not `Versions`, which must keep resolving to {Async::Matrix::Versions}.
      class ServerVersions < Representation
        include Versioned

        # @returns [Array(String)] the specification versions, e.g. `v1.17`.
        def versions
          self.value[:versions] || []
        end

        # @parameter version [String] a specification version.
        # @returns [Boolean] whether the server implements it.
        def supports?(version)
          self.versions.include?(version)
        end
      end

      # The specification versions an identity server implements.
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

        # The versions the server implements. No authentication is required.
        #
        # @returns [ServerVersions] what it implements.
        def get_versions
          api::ServerVersions.get(@resource.with(path: "#{IDENTITY}/versions"))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
