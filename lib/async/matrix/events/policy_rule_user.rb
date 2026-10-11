# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/policy_rule_user"

module Async
  module Matrix
    module Events
      class PolicyRuleUser < Content
        class << self
          def event_type = "m.policy.rule.user"

          def framing = :state_event
        end

        def entity = @value[:entity]

        def recommendation = @value[:recommendation]

        def reason = @value[:reason]
      end
    end
  end
end
