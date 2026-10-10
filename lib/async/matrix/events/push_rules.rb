# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

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
