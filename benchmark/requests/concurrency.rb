# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require_relative "stub"

# Whether requests under one reactor actually overlap, which is the whole reason this library is async.
#
# The same number of requests is made at each concurrency, against a stub which answers after a fixed delay. If the waiting overlaps, the time falls as the concurrency rises and the speedup against sequential is the number worth quoting. If it did not overlap, the curve would be flat - and a flat curve here is the one result in this directory that would mean something was badly wrong.
#
# This measures the client, not a homeserver: see stub.rb for why it cannot be the other way round. The per-concurrency figures are recorded rather than printed: read them with `jq .per_concurrency`.

# How many requests each level makes, which is the same at every level so the levels can be compared.
REQUESTS = Integer(ENV.fetch("REQUESTS", 64))

# The concurrencies swept. One is the sequential case, and the last is every request in flight at once.
CONCURRENCIES = ENV.fetch("CONCURRENCIES", "1,2,8,32,64").split(",").map{|level| Integer(level)}

# Kept across the iterations, so a level is reported by the median of every sample taken of it.
SAMPLES = Hash.new{|samples, level| samples[level] = []}

Stub.run do |client|
  unless Stub.answered_by_stub?(client)
    raise "Something other than the stub answered: the measurement would be of whatever that is."
  end

  run_benchmark(maximum: 20) do
    CONCURRENCIES.each do |level|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Slices of the level's size: each slice is in flight together, and the slices follow one another.
      (0...REQUESTS).each_slice(level) do |slice|
        slice.map{Async{client.versions}}.each(&:wait)
      end

      SAMPLES[level] << Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    end

    timings = SAMPLES.transform_values{|samples| median(samples)}
    sequential = timings[CONCURRENCIES.first]

    {
      requests: REQUESTS,
      delay: Stub::DELAY,
      per_concurrency: timings,
      requests_per_second: timings.transform_values{|seconds| REQUESTS / seconds},
      speedup: timings.transform_values{|seconds| sequential / seconds},
    }
  end
end
