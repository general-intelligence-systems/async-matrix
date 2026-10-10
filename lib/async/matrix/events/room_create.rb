# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomCreate < Content
        class << self
          def event_type = "m.room.create"

          def framing = :state_event
        end

        def creator = @value[:creator]

        def federate = @value[:"m.federate"]

        def room_version = @value[:room_version]

        def room_type = @value[:type]

        def predecessor = @value[:predecessor]

        def additional_creators = @value[:additional_creators]
      end
    end
  end
end
