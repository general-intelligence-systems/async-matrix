# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/call_invite"

module Async
  module Matrix
    module Events
      class CallInvite < Content
        class << self
          def event_type = "m.call.invite"

          def framing = :room_event
        end

        def call_id = @value[:call_id]

        def voip_version = @value[:version]
      end
    end
  end
end
