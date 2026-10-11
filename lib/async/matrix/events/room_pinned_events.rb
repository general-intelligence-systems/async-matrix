# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_pinned_events"

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
