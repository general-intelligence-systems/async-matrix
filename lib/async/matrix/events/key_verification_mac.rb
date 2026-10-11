# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_mac"

module Async
  module Matrix
    module Events
      class KeyVerificationMac < Content
        class << self
          def event_type = "m.key.verification.mac"

          def framing = :event
        end

        include Relates

        def transaction_id = @value[:transaction_id]

        def mac = @value[:mac]

        def keys = @value[:keys]
      end
    end
  end
end
