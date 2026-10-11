# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "benchmark/ips"

require_relative "../harness/common"

# The benchmark-ips harness, which drives the same benchmark as a rate rather than as a time.
#
# What it is for is the subjects which happen many times per response - decoding an event, signing a request - where iterations per second is the number worth quoting, and where benchmark-ips decides how long to run for rather than being told.

# Which harness drove the run, recorded with its results.
HARNESS = "harness-bips"

# How long benchmark-ips spends warming up, and how long it then measures for, in seconds.
WARMUP_TIME = Float(ENV.fetch("WARMUP_TIME", 2))
MEASUREMENT_TIME = Float(ENV.fetch("MEASUREMENT_TIME", 5))

# Measure the block as a rate, and report what it managed.
#
# The iteration bound a benchmark asks for is ignored: benchmark-ips decides how long to run for itself.
def run_benchmark(maximum: nil, &block)
  report = Benchmark.ips do |benchmark|
    benchmark.config(warmup: WARMUP_TIME, time: MEASUREMENT_TIME)
    benchmark.report(benchmark_name, &block)
  end

  entry = report.entries.first

  write_results(
    iterations_per_second: entry.ips,
    standard_deviation: entry.ips_sd,
    relative_deviation: entry.error_percentage,
    iterations: entry.iterations,
    mean: 1.0 / entry.ips,
  )
end
