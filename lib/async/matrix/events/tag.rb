# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/tag"

module Async
  module Matrix
    module Events
      class Tag < Content
        class << self
          def event_type = "m.tag"

          def framing = :event
        end

        def tags = @value[:tags]
      end
    end
  end
end
