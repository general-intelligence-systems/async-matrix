# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/policy_rule_room"

module Async
  module Matrix
    module Events
      class PolicyRuleRoom < Content
        class << self
          def event_type = "m.policy.rule.room"

          def framing = :state_event
        end

        def entity = @value[:entity]

        def recommendation = @value[:recommendation]

        def reason = @value[:reason]
      end
    end
  end
end
