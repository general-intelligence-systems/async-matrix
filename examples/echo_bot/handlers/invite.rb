# frozen_string_literal: true

require "console"

module EchoBot
  module Handlers
    # Handles m.room.member events to auto-join rooms when the bot is invited.
    #
    # A handler must respond to:
    #   #event_types -> Array<String>
    #   #call(event) -> void
    class Invite
      attr_reader :client

      def initialize(client)
        @client = client
      end

      def event_types
        ["m.room.member"]
      end

      def call(event)
      if event.content&.membership == "invite" &&
         event.state_key == client.config.bot_mxid

        Console.info(self) {
          "Invited to #{event.room_id} by #{event.sender} — joining"
        }

        client.join_room(event.room_id)
      end
      rescue => e
        Console.error(self) {
          "Failed to join #{event.room_id}: #{e.message}"
        }
      end
    end
  end
end
