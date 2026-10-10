# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class Reaction < Content
        class << self
          def event_type = "m.reaction"

          def framing = :room_event
        end

        include Relates
      end
    end
  end
end
