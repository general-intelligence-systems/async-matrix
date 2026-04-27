# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"

module Async
  module Matrix
    module ApplicationService
      # In-memory idempotency store for appservice transaction IDs.
      class TransactionStore
        DEFAULT_CAPACITY = 1024

        def initialize(capacity: DEFAULT_CAPACITY)
          @seen     = {}
          @capacity = capacity
        end

        def seen?(txn_id)
          @seen.key?(txn_id)
        end

        def mark_seen(txn_id)
          prune! if @seen.size >= @capacity
          @seen[txn_id] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def size
          @seen.size
        end

        private

          def prune!
            sorted = @seen.sort_by { |_, ts| ts }
            drop   = sorted.size / 2
            sorted.first(drop).each { |id, _| @seen.delete(id) }
          end
      end
    end
  end
end

test do
  describe "Async::Matrix::ApplicationService::TransactionStore" do
    it "tracks seen transaction IDs" do
      store = Async::Matrix::ApplicationService::TransactionStore.new
      store.seen?("txn1").should == false
      store.mark_seen("txn1")
      store.seen?("txn1").should == true
    end

    it "reports size" do
      store = Async::Matrix::ApplicationService::TransactionStore.new
      store.size.should == 0
      store.mark_seen("a")
      store.mark_seen("b")
      store.size.should == 2
    end

    it "prunes oldest entries when capacity is reached" do
      store = Async::Matrix::ApplicationService::TransactionStore.new(capacity: 4)
      store.mark_seen("a")
      store.mark_seen("b")
      store.mark_seen("c")
      store.mark_seen("d")
      # This triggers prune — drops oldest half (a, b)
      store.mark_seen("e")
      store.seen?("a").should == false
      store.seen?("b").should == false
      store.seen?("d").should == true
      store.seen?("e").should == true
    end

    it "does not prune below capacity" do
      store = Async::Matrix::ApplicationService::TransactionStore.new(capacity: 10)
      5.times { |i| store.mark_seen("txn#{i}") }
      store.size.should == 5
      store.seen?("txn0").should == true
    end
  end
end
