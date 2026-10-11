# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_encryption"

module Async
  module Matrix
    module Events
      class RoomEncryption < Content
        class << self
          def event_type = "m.room.encryption"

          def framing = :state_event
        end

        def algorithm = @value[:algorithm]

        def rotation_period_ms = @value[:rotation_period_ms]

        def rotation_period_msgs = @value[:rotation_period_msgs]
      end
    end
  end
end
