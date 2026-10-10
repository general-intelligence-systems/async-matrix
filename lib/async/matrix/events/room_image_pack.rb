# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

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
