# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "common"

# The default harness, which times the block with the monotonic clock and counts what it allocated.
#
# Timing rather than iterations per second, because the subjects it was written for are each done once per process or once per request - loading the library, building the classes for a version - and a rate is not what anybody asks of those.

# Which harness drove the run, recorded with its results.
HARNESS = "harness"

# How many iterations are thrown away before measurement starts, so that what is measured is warm code rather than the first time through it.
WARMUP_ITERATIONS = Integer(ENV.fetch("WARMUP_ITERATIONS", 5))

# The fewest iterations to measure, and the least time to spend measuring: a run goes on until both are satisfied.
MINIMUM_ITERATIONS = Integer(ENV.fetch("MINIMUM_ITERATIONS", 10))
MINIMUM_TIME = Float(ENV.fetch("MINIMUM_TIME", 5))

# The most iterations to run, whatever MINIMUM_TIME has to say about it. A block faster than a millisecond would otherwise be asked for millions of them, which is a rate measured badly: that is what harness-bips is for.
MAXIMUM_ITERATIONS = Integer(ENV.fetch("MAXIMUM_ITERATIONS", 1_000))

# How many iterations are reported one by one before the run goes quiet, so that a short benchmark can be watched and a long one does not bury its own summary.
REPORTED_ITERATIONS = Integer(ENV.fetch("REPORTED_ITERATIONS", 20))

# Time the block, and report what it took.
#
# A benchmark whose iteration is expensive enough that a thousand buys no precision worth the wall clock says so with `maximum`.
def run_benchmark(maximum: MAXIMUM_ITERATIONS, &block)
  timings = []
  allocations = []
  measured = {}

  begin
    allocated = GC.stat(:total_allocated_objects)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = block.call

    timings << Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    allocations << GC.stat(:total_allocated_objects) - allocated

    # A benchmark which measured something the harness cannot see for itself says so by returning it:
    if result.is_a?(Hash)
      measured = result
    end

    if timings.size <= REPORTED_ITERATIONS
      puts format("%5s %9.3fms", "##{timings.size}:", timings.last * 1000)
    end
  end until (timings.size >= WARMUP_ITERATIONS + MINIMUM_ITERATIONS and timings.sum >= MINIMUM_TIME) or timings.size >= maximum

  summarize(timings, allocations, measured)
end

# Say what the measured iterations came to, and write them out.
def summarize(timings, allocations, measured)
  # A run cut short by MAXIMUM_ITERATIONS may hold nothing but warmup, and a summary of nothing is worse than a summary of a warm-up:
  discarded = [WARMUP_ITERATIONS, timings.size - 1].min
  measurements = timings.drop(discarded)
  counts = allocations.drop(discarded)
  average = mean(measurements)
  centre = median(measurements)

  # The median leads, because a collection landing in one iteration is a tail rather than a change in what the code costs, and it moves a mean much further than it moves a median. The mean is printed beside it so that the tail is not hidden either:
  puts format(
    "%s: %.3fms +/- %.1f%% (median), %.3fms (mean) over %d samples, %d objects allocated.",
    benchmark_name,
    centre * 1000,
    relative_absolute_deviation(measurements),
    average * 1000,
    measurements.size,
    mean(counts).round,
  )

  write_results(
    warmup: timings.first(discarded),
    timings: measurements,
    median: centre,
    median_absolute_deviation: median_absolute_deviation(measurements),
    relative_absolute_deviation: relative_absolute_deviation(measurements),
    mean: average,
    standard_deviation: standard_deviation(measurements),
    relative_deviation: relative_deviation(measurements),
    allocations: mean(counts),
    **measured,
  )
end
