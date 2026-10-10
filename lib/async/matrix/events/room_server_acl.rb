# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomServerAcl < Content
        class << self
          def event_type = "m.room.server_acl"

          def framing = :state_event
        end

        def allow_ip_literals = @value[:allow_ip_literals]

        def allow = @value[:allow]

        def deny = @value[:deny]
      end
    end
  end
end
