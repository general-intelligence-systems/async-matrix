# frozen_string_literal: true

require "console"

module EchoBot
  module Handlers
    # Handles m.room.message events.
    # Echoes back any text message as a notice.
    #
    # A handler must respond to:
    #   #event_types -> Array<String>
    #   #call(event) -> void
    class Message
      attr_reader :client

      def initialize(client)
        @client = client
      end

      def event_types
        ["m.room.message"]
      end

      def call(event)
        if event.content&.msgtype == "m.text" &&
           event.content.body && !event.content.body.empty? &&
           event.sender != client.config.bot_mxid

          Console.info(self) {
            "Message from #{event.sender} in #{event.room_id}: " \
            "#{event.content.body[0..100]}"
          }

          client.send_notice(event.room_id, "Echo: #{event.content.body}")
        end
      end
    end
  end
end
