# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomRedaction < Content
        class << self
          def event_type = "m.room.redaction"

          def framing = :room_event
        end

        def redacts = @value[:redacts]

        def reason = @value[:reason]
      end
    end
  end
end
