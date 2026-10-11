# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/image_pack_rooms"

module Async
  module Matrix
    module Events
      class ImagePackRooms < Content
        class << self
          def event_type = "m.image_pack.rooms"

          def framing = :event
        end

        def rooms = @value[:rooms]
      end
    end
  end
end
