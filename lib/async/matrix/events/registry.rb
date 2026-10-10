# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "envelope"

module Async
  module Matrix
    module Events
      class Registry
        FRAMINGS = {
          event: Envelope,
          room_event: RoomEvent,
          state_event: StateEvent,
        }.freeze

        class << self
          def for(api)
            @registries ||= {}
            @registries[api] ||= self.new(api)
          end
        end

        def initialize(api)
          @api = api
          @types = {}

          api.constants(false).each do |name|
            klass = api.const_get(name)

            if klass.is_a?(Class) and klass < Content and klass.event_type
              self.register(klass)
            end
          end
        end

        attr :types

        def register(klass)
          entry = (@types[klass.event_type] ||= {variants: {}, default: nil})

          if variant = klass.variant
            entry[:variants][variant] = klass
          else
            entry[:default] = klass
          end
        end

        def content_class(type, value)
          entry = @types[type]

          if entry
            variant = entry[:variants].find do |fields, _|
              fields.all?{|field, expected| value[field] == expected}
            end

            if variant
              variant.last
            else
              entry[:default] || Content
            end
          else
            Content
          end
        end

        def wrap(value, room_id: nil)
          klass = self.content_class(value[:type], value[:content] || {})

          self.envelope_class(klass, value).new(value, klass.new(value[:content] || {}), room_id: room_id)
        end

        def content(type, value) = self.content_class(type, value).new(value)

        private

        def envelope_class(klass, value)
          if klass.event_type
            FRAMINGS.fetch(klass.framing, RoomEvent)
          elsif value.key?(:state_key)
            StateEvent
          elsif value.key?(:event_id)
            RoomEvent
          else
            Envelope
          end
        end
      end
    end
  end
end
