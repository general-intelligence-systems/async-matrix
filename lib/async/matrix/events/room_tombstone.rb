# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

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
