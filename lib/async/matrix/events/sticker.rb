# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
