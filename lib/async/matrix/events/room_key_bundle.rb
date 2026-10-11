# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_key_bundle"

module Async
  module Matrix
    module Events
      class RoomKeyBundle < Content
        class << self
          def event_type = "m.room_key_bundle"

          def framing = :event
        end

        def room_id = @value[:room_id]

        def file = @value[:file]
      end
    end
  end
end
