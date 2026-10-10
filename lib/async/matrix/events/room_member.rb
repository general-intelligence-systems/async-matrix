# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class RoomMember < Content
        class << self
          def event_type = "m.room.member"

          def framing = :state_event
        end

        def avatar_url = @value[:avatar_url]

        def displayname = @value[:displayname]

        def membership = @value[:membership]

        def is_direct = @value[:is_direct]

        def join_authorised_via_users_server = @value[:join_authorised_via_users_server]

        def reason = @value[:reason]

        def third_party_invite = @value[:third_party_invite]
      end
    end
  end
end
