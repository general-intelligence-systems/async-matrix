# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomTopic < Content
        class << self
          def event_type = "m.room.topic"

          def framing = :state_event
        end

        def topic = @value[:topic]

        def m_topic = @value[:"m.topic"]
      end
    end
  end
end
