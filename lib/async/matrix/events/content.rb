# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../versioned"
require_relative "readers"

module Async
  module Matrix
    module Events
      class Content
        extend Readers

        include Versioned

        class << self
          def event_type = nil

          def variant = nil

          def framing = :event

          def build(**fields) = self.new(self.variant.to_h.merge(fields))
        end

        def initialize(value = {})
          @value = value
        end

        attr :value

        def type = self.class.event_type

        def deconstruct_keys(keys) = @value

        def [](key) = @value[key]

        def dig(*keys) = @value.dig(*keys)

        def to_h = @value

        def ==(other) = (other.is_a?(Content) and other.class.event_type == self.class.event_type and other.to_h == @value)

        def inspect = "\#<#{self.class} #{@value.inspect}>"
      end
    end
  end
end
