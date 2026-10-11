# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_third_party_invite"

module Async
  module Matrix
    module Events
      class RoomThirdPartyInvite < Content
        class << self
          def event_type = "m.room.third_party_invite"

          def framing = :state_event
        end

        def display_name = @value[:display_name]

        def key_validity_url = @value[:key_validity_url]

        def public_key = @value[:public_key]

        def public_keys = @value[:public_keys]
      end
    end
  end
end
