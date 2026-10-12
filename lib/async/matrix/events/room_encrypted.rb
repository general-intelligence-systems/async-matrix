# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_encrypted"

module Async
  module Matrix
    module Events
      class RoomEncrypted < Content
        class << self
          def event_type = "m.room.encrypted"

          def framing = :room_event
        end

        def algorithm = @value[:algorithm]

        def ciphertext = @value[:ciphertext]

        def sender_key = @value[:sender_key]

        def device_id = @value[:device_id]

        def session_id = @value[:session_id]
      end
    end
  end
end
