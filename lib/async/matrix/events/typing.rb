# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class Typing < Content
        class << self
          def event_type = "m.typing"

          def framing = :event
        end

        def user_ids = @value[:user_ids]
      end
    end
  end
end
