# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/dummy"

module Async
  module Matrix
    module Events
      class Dummy < Content
        class << self
          def event_type = "m.dummy"

          def framing = :event
        end
      end
    end
  end
end
