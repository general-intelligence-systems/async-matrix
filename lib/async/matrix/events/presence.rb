# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/presence"

module Async
  module Matrix
    module Events
      class Presence < Content
        class << self
          def event_type = "m.presence"

          def framing = :event
        end

        def avatar_url = @value[:avatar_url]

        def displayname = @value[:displayname]

        def last_active_ago = @value[:last_active_ago]

        def presence = @value[:presence]

        def currently_active = @value[:currently_active]

        def status_msg = @value[:status_msg]
      end
    end
  end
end
