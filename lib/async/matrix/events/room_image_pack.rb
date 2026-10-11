# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_image_pack"

module Async
  module Matrix
    module Events
      class RoomImagePack < Content
        class << self
          def event_type = "m.room.image_pack"

          def framing = :state_event
        end

        def images = @value[:images]

        def pack = @value[:pack]
      end
    end
  end
end
