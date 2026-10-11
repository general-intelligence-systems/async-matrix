# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require "async/matrix"

# How the cost of building a version scales with the version, which is the curve this library is shaped to produce.
#
# A version is layered from every version up to it, so v1.19 includes nineteen layers per class where v1.1 includes one. The sweep says whether that is what the clock sees, and is where a layer which is doing more than it looks would show up. The per-version figures are recorded rather than printed: read them with `jq .per_version`.

# The API built, which is the largest of them.
NAMESPACE = Async::Matrix::ClientServer

# Bounded because each iteration derives the classes of all nineteen versions, which is the slowest iteration here by a long way.
# Kept across the iterations rather than within one, so that a version is reported by the median of every sample taken of it: one sample apiece would be one collection away from saying nothing.
SAMPLES = Hash.new{|samples, version| samples[version] = []}

run_benchmark(maximum: 20) do
  Async::Matrix::VERSIONS.each do |version|
    Async::Matrix::Versions.instance_variable_set(:@apis, nil)

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Async::Matrix::Versions[version, NAMESPACE]

    SAMPLES[version] << Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  {per_version: SAMPLES.transform_values{|samples| median(samples)}}
end
