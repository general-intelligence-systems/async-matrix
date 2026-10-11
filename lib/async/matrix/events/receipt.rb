# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/receipt"

module Async
  module Matrix
    module Events
      class Receipt < Content
        class << self
          def event_type = "m.receipt"

          def framing = :event
        end

        include Enumerable

        def each(&block) = @value.each(&block)
      end
    end
  end
end
