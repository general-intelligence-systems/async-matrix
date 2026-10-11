# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_tombstone"

module Async
  module Matrix
    module Events
      class RoomTombstone < Content
        class << self
          def event_type = "m.room.tombstone"

          def framing = :state_event
        end

        def body = @value[:body]

        def replacement_room = @value[:replacement_room]
      end
    end
  end
end
