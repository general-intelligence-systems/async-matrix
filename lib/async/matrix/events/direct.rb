# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/direct"

module Async
  module Matrix
    module Events
      class Direct < Content
        class << self
          def event_type = "m.direct"

          def framing = :event
        end

        include Enumerable

        def each(&block) = @value.each(&block)
      end
    end
  end
end
