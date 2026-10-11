# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_key_request"

module Async
  module Matrix
    module Events
      class RoomKeyRequest < Content
        class << self
          def event_type = "m.room_key_request"

          def framing = :event
        end

        def body = @value[:body]

        def action = @value[:action]

        def requesting_device_id = @value[:requesting_device_id]

        def request_id = @value[:request_id]
      end
    end
  end
end
