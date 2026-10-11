# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_key"

module Async
  module Matrix
    module Events
      class RoomKey < Content
        class << self
          def event_type = "m.room_key"

          def framing = :event
        end

        def algorithm = @value[:algorithm]

        def room_id = @value[:room_id]

        def session_id = @value[:session_id]

        def session_key = @value[:session_key]
      end
    end
  end
end
