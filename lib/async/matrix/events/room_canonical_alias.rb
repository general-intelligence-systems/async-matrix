# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_canonical_alias"

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
