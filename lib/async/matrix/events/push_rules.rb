# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/push_rules"

module Async
  module Matrix
    module Events
      class PushRules < Content
        class << self
          def event_type = "m.push_rules"

          def framing = :event
        end

        def global = @value[:global]
      end
    end
  end
end
