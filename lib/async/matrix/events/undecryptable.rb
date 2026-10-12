# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"

module Async
  module Matrix
    module Events
      # A message which could not be read, which no homeserver ever sends.
      #
      # These are synthesised where the ciphertext was, so that a sync loop can say why a message is missing in the same `case` which reads the ones that are not.
      class Undecryptable < Content
        class << self
          def event_type = "m.room.encrypted.undecryptable"

          def framing = :room_event
        end

        def algorithm = @value[:algorithm]

        def room_id = @value[:room_id]

        def session_id = @value[:session_id]

        def sender_key = @value[:sender_key]

        # @returns [String | nil] what went wrong, where anything is known.
        def reason = @value[:reason]
      end

      # A message whose session has not arrived, which it still may.
      #
      # The event is kept, so it comes back through the loop if the key turns up.
      class Deferred < Undecryptable
        class << self
          def event_type = "m.room.encrypted.deferred"
        end
      end

      # A message whose session was deliberately refused, with the reason the sender gave.
      #
      # Only `m.unverified` ends: the rest say the wait is over.
      class Withheld < Undecryptable
        class << self
          def event_type = "m.room.encrypted.withheld"
        end

        def code = @value[:code]
      end
    end
  end
end
