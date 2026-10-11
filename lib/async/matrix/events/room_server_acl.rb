# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_server_acl"

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
