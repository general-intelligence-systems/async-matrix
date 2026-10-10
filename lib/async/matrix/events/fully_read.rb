# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class FullyRead < Content
        class << self
          def event_type = "m.fully_read"

          def framing = :event
        end

        def event_id = @value[:event_id]
      end
    end
  end
end
