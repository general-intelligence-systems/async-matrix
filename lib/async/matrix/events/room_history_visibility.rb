# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_history_visibility"

module Async
  module Matrix
    module Events
      class RoomHistoryVisibility < Content
        class << self
          def event_type = "m.room.history_visibility"

          def framing = :state_event
        end

        def history_visibility = @value[:history_visibility]
      end
    end
  end
end
