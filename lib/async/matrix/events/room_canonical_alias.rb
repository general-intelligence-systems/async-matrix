# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomCanonicalAlias < Content
        class << self
          def event_type = "m.room.canonical_alias"

          def framing = :state_event
        end

        def alias = @value[:alias]

        def alt_aliases = @value[:alt_aliases]
      end
    end
  end
end
