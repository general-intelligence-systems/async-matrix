# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

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
