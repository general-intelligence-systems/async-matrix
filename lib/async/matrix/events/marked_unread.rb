# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/marked_unread"

module Async
  module Matrix
    module Events
      class MarkedUnread < Content
        class << self
          def event_type = "m.marked_unread"

          def framing = :event
        end

        def unread = @value[:unread]
      end
    end
  end
end
