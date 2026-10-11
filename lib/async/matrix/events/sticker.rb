# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/sticker"

module Async
  module Matrix
    module Events
      class Sticker < Content
        class << self
          def event_type = "m.sticker"

          def framing = :room_event
        end

        def body = @value[:body]

        def info = @value[:info]

        def url = @value[:url]
      end
    end
  end
end
