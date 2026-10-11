# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
