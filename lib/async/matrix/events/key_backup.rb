# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

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
