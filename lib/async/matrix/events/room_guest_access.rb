# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
