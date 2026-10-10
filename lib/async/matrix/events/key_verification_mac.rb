# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

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
