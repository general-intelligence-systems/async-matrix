# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Makes a sync loop run once, so that an example can be run to the end.
#
# Every example finishes with `sync.each`, which is a long poll and never returns. Waiting on one costs whatever timeout it is given, and killing it says only that it got as far as the loop rather than through it.
#
# So this is required ahead of an example, by `ruby -r`: it yields the batch it already has and returns, which runs the body once and lets the process exit. What the body does with that batch is then covered too, rather than only the setup above it.
#
#   ruby -r./fixtures/async/matrix/example_once.rb examples/e2ee/reading_a_message.rb

require_relative "../../../lib/async/matrix"

# Encryption is not part of what `async/matrix` requires, and an example requires it by name.
require_relative "../../../lib/async/matrix/e2ee"

module Async
  module Matrix
    # One batch, and then out.
    module ExampleOnce
      # @yields {|sync| ...}
      #   @parameter sync [Async::Matrix::ClientServer::Sync] the batch already in hand.
      def each(*arguments, **options)
        if block_given?
          yield self
        else
          super
        end
      end
    end

    ClientServer::Sync.prepend(ExampleOnce)
  end
end
