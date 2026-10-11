# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_key"

module Async
  module Matrix
    module Events
      class KeyVerificationKey < Content
        class << self
          def event_type = "m.key.verification.key"

          def framing = :event
        end

        include Relates

        def transaction_id = @value[:transaction_id]

        def key = @value[:key]
      end
    end
  end
end
