# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
