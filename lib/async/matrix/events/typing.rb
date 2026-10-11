# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/typing"

module Async
  module Matrix
    module Events
      class Typing < Content
        class << self
          def event_type = "m.typing"

          def framing = :event
        end

        def user_ids = @value[:user_ids]
      end
    end
  end
end
