# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomEncrypted < Content
        class << self
          def event_type = "m.room.encrypted"

          def framing = :event
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
