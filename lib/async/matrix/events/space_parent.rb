# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/space_parent"

module Async
  module Matrix
    module Events
      class SpaceParent < Content
        class << self
          def event_type = "m.space.parent"

          def framing = :state_event
        end

        def via = @value[:via]

        def canonical = @value[:canonical]
      end
    end
  end
end
