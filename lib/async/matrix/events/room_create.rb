# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_create"

module Async
  module Matrix
    module Events
      class RoomCreate < Content
        class << self
          def event_type = "m.room.create"

          def framing = :state_event
        end

        def creator = @value[:creator]

        reads "m.federate"

        def room_version = @value[:room_version]

        def predecessor = @value[:predecessor]
      end
    end
  end
end
