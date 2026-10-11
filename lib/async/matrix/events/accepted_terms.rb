# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/accepted_terms"

module Async
  module Matrix
    module Events
      class AcceptedTerms < Content
        class << self
          def event_type = "m.accepted_terms"

          def framing = :event
        end

        def accepted = @value[:accepted]
      end
    end
  end
end
