# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomJoinRules < Content
        class << self
          def event_type = "m.room.join_rules"

          def framing = :state_event
        end

        def join_rule = @value[:join_rule]

        def allow = @value[:allow]
      end
    end
  end
end
