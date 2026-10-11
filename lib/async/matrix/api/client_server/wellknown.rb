# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/wellknown"

module Async
  module Matrix
    module ClientServer
      # What a domain says about where its homeserver is.
      class Discovery < Representation
        include Versioned

        # @returns [Hash] the homeserver, which carries its `base_url`.
        def homeserver
          self.value[:"m.homeserver"] || {}
        end

        # @returns [String | nil] the base URL to make requests against.
        def base_url
          self.homeserver[:base_url]
        end

        # @returns [Hash | nil] the identity server, where the domain names one.
        def identity_server
          self.value[:"m.identity_server"]
        end
      end

      # Where a client should look for the homeserver.
      class Wellknown
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Wellknown] the document.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Where the homeserver for this domain is. No authentication is required.
        #
        # The path is the domain's own.
        #
        # @returns [Discovery] where to make requests.
        def get_wellknown
          api::Discovery.get(@resource.with(path: "/.well-known/matrix/client"))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
