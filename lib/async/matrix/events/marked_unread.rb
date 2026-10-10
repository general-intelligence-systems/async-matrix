# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

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
