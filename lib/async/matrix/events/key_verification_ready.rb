# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_ready"

module Async
  module Matrix
    module Events
      class KeyVerificationReady < Content
        class << self
          def event_type = "m.key.verification.ready"

          def framing = :event
        end

        include Relates

        def from_device = @value[:from_device]

        def transaction_id = @value[:transaction_id]

        def verification_methods = @value[:methods]
      end
    end
  end
end
