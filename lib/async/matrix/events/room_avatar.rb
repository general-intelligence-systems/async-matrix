# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_avatar"

module Async
  module Matrix
    module Events
      class RoomAvatar < Content
        class << self
          def event_type = "m.room.avatar"

          def framing = :state_event
        end

        def info = @value[:info]

        def url = @value[:url]
      end
    end
  end
end
