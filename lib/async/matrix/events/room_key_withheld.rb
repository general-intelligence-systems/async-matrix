# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_key_withheld"

module Async
  module Matrix
    module Events
      class RoomKeyWithheld < Content
        class << self
          def event_type = "m.room_key.withheld"

          def framing = :event
        end

        def algorithm = @value[:algorithm]

        def room_id = @value[:room_id]

        def session_id = @value[:session_id]

        def sender_key = @value[:sender_key]

        def code = @value[:code]

        def reason = @value[:reason]
      end
    end
  end
end
