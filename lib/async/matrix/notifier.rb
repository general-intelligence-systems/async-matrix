# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async"
require "async/condition"
require "async/matrix"

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

test do
  it "can be instantiated" do
    notifier = Async::Matrix::Notifier.new
    notifier.should.be.kind_of Async::Matrix::Notifier
  end

  it "responds to #signal" do
    Async::Matrix::Notifier.new.should.respond_to :signal
  end

  it "responds to #wait" do
    Async::Matrix::Notifier.new.should.respond_to :wait
  end

  it "returns truthy block value immediately without waiting" do
    Async do
      notifier = Async::Matrix::Notifier.new
      result = notifier.wait(timeout: 1) { :data }
      result.should == :data
    end.wait
  end

  it "returns falsy block value on timeout" do
    Async do
      notifier = Async::Matrix::Notifier.new
      result = notifier.wait(timeout: 0.05) { nil }
      result.should.be.nil
    end.wait
  end

  it "wakes waiting fibers on signal" do
    result = nil
    Async do |task|
      notifier = Async::Matrix::Notifier.new
      signalled = false

      task.async do
        result = notifier.wait(timeout: 5) { signalled }
      end

      task.async do
        signalled = true
        notifier.signal
      end
    end.wait
    result.should == true
  end
end
