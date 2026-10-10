# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
