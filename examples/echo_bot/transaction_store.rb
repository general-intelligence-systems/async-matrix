# frozen_string_literal: true

module EchoBot
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
