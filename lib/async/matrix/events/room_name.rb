# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomName < Content
        class << self
          def event_type = "m.room.name"

          def framing = :state_event
        end

        def name = @value[:name]
      end
    end
  end
end
