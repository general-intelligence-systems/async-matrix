# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class ForwardedRoomKey < Content
        class << self
          def event_type = "m.forwarded_room_key"

          def framing = :event
        end

        def algorithm = @value[:algorithm]

        def room_id = @value[:room_id]

        def sender_key = @value[:sender_key]

        def session_id = @value[:session_id]

        def session_key = @value[:session_key]

        def sender_claimed_ed25519_key = @value[:sender_claimed_ed25519_key]

        def forwarding_curve25519_key_chain = @value[:forwarding_curve25519_key_chain]

        def withheld = @value[:withheld]
      end
    end
  end
end
