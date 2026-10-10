# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomPolicy < Content
        class << self
          def event_type = "m.room.policy"

          def framing = :state_event
        end

        def via = @value[:via]

        def public_keys = @value[:public_keys]
      end
    end
  end
end
