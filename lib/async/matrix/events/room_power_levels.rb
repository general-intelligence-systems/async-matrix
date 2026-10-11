# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_power_levels"

module Async
  module Matrix
    module Events
      class RoomPowerLevels < Content
        class << self
          def event_type = "m.room.power_levels"

          def framing = :state_event
        end

        def ban = @value[:ban]

        def events = @value[:events]

        def events_default = @value[:events_default]

        def invite = @value[:invite]

        def kick = @value[:kick]

        def redact = @value[:redact]

        def state_default = @value[:state_default]

        def users = @value[:users]

        def users_default = @value[:users_default]

        def notifications = @value[:notifications]
      end
    end
  end
end
