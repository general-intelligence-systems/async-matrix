# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_m_relates_to"

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
