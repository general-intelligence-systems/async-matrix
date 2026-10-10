# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomPinnedEvents < Content
        class << self
          def event_type = "m.room.pinned_events"

          def framing = :state_event
        end

        def pinned = @value[:pinned]
      end
    end
  end
end
