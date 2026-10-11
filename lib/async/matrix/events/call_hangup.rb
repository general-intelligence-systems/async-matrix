# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/call_hangup"

module Async
  module Matrix
    module Events
      class CallHangup < Content
        class << self
          def event_type = "m.call.hangup"

          def framing = :room_event
        end

        def call_id = @value[:call_id]

        def voip_version = @value[:version]
      end
    end
  end
end
