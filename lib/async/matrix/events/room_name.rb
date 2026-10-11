# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_name"

module Async
  module Matrix
    module Events
      class RoomName < Content
        class << self
          def event_type = "m.room.name"

          def framing = :state_event
        end

        def name = @value[:name]
      end
    end
  end
end
