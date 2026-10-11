# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_message_feedback"

module Async
  module Matrix
    module Events
      # Acknowledges a message, which v1.3 dropped in favour of the receipts module: it is described by v1.1 and v1.2 alone, and the class exists so that those versions have one.
      class RoomMessageFeedback < Content
        class << self
          def event_type = "m.room.message.feedback"

          def framing = :room_event
        end

        def target_event_id = @value[:target_event_id]

        # @returns [String] `delivered` or `read`. Not `type`, which is the event type.
        def feedback_type = @value[:type]
      end
    end
  end
end
