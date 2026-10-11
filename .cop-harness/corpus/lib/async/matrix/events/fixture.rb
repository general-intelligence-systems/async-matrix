# frozen_string_literal: true

module Async
  module Matrix
    module Events
      # An event.
      class Fixture
        # @returns [String] the type.
        def event_type
          "m.room.message"
        end

        # @parameter fields [Hash] the fields.
        # @returns [Fixture] the fixture.
        def build(**fields)
          new(fields)
        end

        # @returns [String] the type.
        def already = "m.room.other"

        # @returns [Integer] the sum.
        def multi
          a = 1
          a + 1
        end
      end
    end
  end
end
