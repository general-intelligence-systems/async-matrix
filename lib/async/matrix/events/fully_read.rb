# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/fully_read"

module Async
  module Matrix
    module Events
      class FullyRead < Content
        class << self
          def event_type = "m.fully_read"

          def framing = :event
        end

        def event_id = @value[:event_id]
      end
    end
  end
end
