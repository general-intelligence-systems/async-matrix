# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "versions"

require_relative "events/content"
require_relative "events/fields"
require_relative "events/envelope"
require_relative "events/registry"
require_relative "events/room_message"

module Async
  module Matrix
    # The events which flow through the API: the values a representation carries, rather than the
    # resources it describes.
    #
    # The classes here are versioned the same way the API classes are, so the registry a
    # representation inflates with comes from the version it was built for.
    module Events
      class << self
        # The events built for a given specification version.
        #
        # @parameter version [String | Symbol] e.g. `"v1.19"`.
        # @returns [Module] the generated events.
        def [](version)
          Versions[version, self]
        end

        # The registry for a version, which maps an event onto the class describing it.
        #
        # An unversioned caller gets the unversioned classes, which carry every field the latest
        # version describes.
        #
        # @parameter version [String | Symbol | nil] e.g. `"v1.19"`.
        # @returns [Registry] the registry.
        def registry(version = nil)
          if version
            Registry.for(self[version])
          else
            Registry.for(self)
          end
        end
      end
    end
  end
end
