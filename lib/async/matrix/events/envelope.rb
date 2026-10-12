# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Events
      class Envelope
        def initialize(value, content, room_id: nil)
          @value = value
          @content = content
          @room_id = room_id
        end

        attr :value

        attr :content

        def type = @value[:type]

        def deconstruct_keys(keys) = {type: self.type, content: @content}

        def [](key) = @value[key]

        def dig(*keys) = @value.dig(*keys)

        def to_h = @value

        def inspect = "\#<#{self.class} #{self.type}>"
      end

      class RoomEvent < Envelope
        def event_id = @value[:event_id]

        def sender = @value[:sender]

        def origin_server_ts = @value[:origin_server_ts]

        def unsigned = @value[:unsigned]

        def room_id = @value[:room_id] || @room_id

        def deconstruct_keys(keys)
          super.merge(
            event_id: self.event_id,
            sender: self.sender,
            origin_server_ts: self.origin_server_ts,
            unsigned: self.unsigned,
            room_id: self.room_id,
          )
        end
      end

      class StateEvent < RoomEvent
        def state_key = @value[:state_key]

        def prev_content = @value[:prev_content]

        def deconstruct_keys(keys) = super.merge(state_key: self.state_key, prev_content: self.prev_content)
      end

      # An event which arrived encrypted, carrying the plaintext and where it came from.
      #
      # So a pattern reads it as any other event, or asks about the session it came over.
      class Decrypted < RoomEvent
        def initialize(value, content, room_id: nil, session_id: nil, message_index: nil, released: false, sender_device_keys: false)
          super(value, content, room_id: room_id)

          @session_id = session_id
          @message_index = message_index
          @released = released
          @sender_device_keys = sender_device_keys
        end

        # @attribute [String] the session this event was encrypted with.
        attr :session_id

        # @attribute [Integer | nil] the index it was sent at, which a replay is recognised by.
        attr :message_index

        # @returns [Boolean] whether it was waiting for its key rather than read as it arrived.
        def released? = @released

        # @returns [Boolean] whether the sender proved its own device keys inside the ciphertext.
        def sender_device_keys? = @sender_device_keys

        def deconstruct_keys(keys)
          super.merge(
            session_id: @session_id,
            message_index: @message_index,
            released: @released,
            sender_device_keys: @sender_device_keys,
          )
        end
      end
    end
  end
end
