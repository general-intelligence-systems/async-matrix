# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_guest_access"

module Async
  module Matrix
    module Events
      class RoomGuestAccess < Content
        class << self
          def event_type = "m.room.guest_access"

          def framing = :state_event
        end

        def guest_access = @value[:guest_access]
      end
    end
  end
end
