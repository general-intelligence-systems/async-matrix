# frozen_string_literal: true

require 'async'
require 'async/condition'

module Async
  module Matrix
    # Waitable event bus. Signal it when events arrive;
    # /sync handlers wait on it with a timeout.
    #
    #   notifier = Async::Matrix::Notifier.new
    #
    #   # In a /sync handler fiber (blocks until signalled or timeout):
    #   notifier.wait(timeout: 30) { check_for_events() }
    #
    #   # After persisting an event (wakes all waiting fibers):
    #   notifier.signal
    #
    class Notifier
      def initialize
        @condition = Async::Condition.new
      end

      # Wake all waiting fibers.
      def signal
        @condition.signal
      end

      # Block up to +timeout+ seconds. Yields to check for data after
      # each wake-up; returns the block's value as soon as it is truthy.
      # Returns the block's value (possibly nil/false) when time runs out.
      def wait(timeout: 30, &block)
        deadline = Time.now + timeout

        loop do
          result = yield
          return result if result

          remaining = deadline - Time.now
          return result if remaining <= 0

          begin
            Async::Task.current.with_timeout(remaining) do
              @condition.wait
            end
          rescue Async::TimeoutError
            return yield
          end
        end
      end
    end
  end
end
