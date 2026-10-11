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
    end
  end
end
