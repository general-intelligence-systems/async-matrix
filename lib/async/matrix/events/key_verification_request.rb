# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_request"

module Async
  module Matrix
    module Events
      class KeyVerificationRequest < Content
        class << self
          def event_type = "m.key.verification.request"

          def framing = :event
        end

        def from_device = @value[:from_device]

        def transaction_id = @value[:transaction_id]

        def verification_methods = @value[:methods]

        def timestamp = @value[:timestamp]
      end
    end
  end
end
