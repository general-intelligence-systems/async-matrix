# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_backup"

module Async
  module Matrix
    module Events
      class KeyBackup < Content
        class << self
          def event_type = "m.key_backup"

          def framing = :event
        end

        def enabled = @value[:enabled]
      end
    end
  end
end
