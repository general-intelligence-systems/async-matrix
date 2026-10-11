# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_done"

module Async
  module Matrix
    module Events
      class KeyVerificationDone < Content
        class << self
          def event_type = "m.key.verification.done"

          def framing = :event
        end

        include Relates

        def transaction_id = @value[:transaction_id]
      end
    end
  end
end
