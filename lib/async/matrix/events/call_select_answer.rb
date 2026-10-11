# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/call_select_answer"

module Async
  module Matrix
    module Events
      class CallSelectAnswer < Content
        class << self
          def event_type = "m.call.select_answer"

          def framing = :room_event
        end

        def call_id = @value[:call_id]

        def voip_version = @value[:version]

        def party_id = @value[:party_id]
      end
    end
  end
end
