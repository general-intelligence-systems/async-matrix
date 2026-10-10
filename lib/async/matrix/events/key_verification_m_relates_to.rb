# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class KeyVerificationMRelatesTo < Content
        class << self
          def event_type = "m.key.verification.m.relates_to"

          def framing = :event
        end
      end
    end
  end
end
