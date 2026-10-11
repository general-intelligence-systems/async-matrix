# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_join_rules"

module Async
  module Matrix
    module Events
      class RoomJoinRules < Content
        class << self
          def event_type = "m.room.join_rules"

          def framing = :state_event
        end

        def join_rule = @value[:join_rule]
      end
    end
  end
end
