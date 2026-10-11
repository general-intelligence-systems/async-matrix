# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

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
