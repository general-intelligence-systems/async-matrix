# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/recent_emoji"

module Async
  module Matrix
    module Events
      class RecentEmoji < Content
        class << self
          def event_type = "m.recent_emoji"

          def framing = :event
        end

        def recent_emoji = @value[:recent_emoji]
      end
    end
  end
end
