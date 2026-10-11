# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_redaction"

module Async
  module Matrix
    module Events
      class RoomRedaction < Content
        class << self
          def event_type = "m.room.redaction"

          def framing = :room_event
        end

        def reason = @value[:reason]
      end
    end
  end
end
