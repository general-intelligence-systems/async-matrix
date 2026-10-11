# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require "async/matrix"

# What building the latest version of every API costs, which is what a program using more than one of them pays.
#
# The APIs are not the same size - the client-server API carries more classes than the rest together - so this says which of them a boot figure is actually made of. The per-API figures are recorded rather than printed: read them with `jq .per_namespace`.

# The version built, passed through by bin/benchmark as it is for the suite.
VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

# The APIs, which are the modules holding versioned classes. There is no list to keep in step: a namespace is one by holding them.
NAMESPACES = Async::Matrix.constants(false).filter_map do |name|
  value = Async::Matrix.const_get(name)

  if value.is_a?(Module) and !value.is_a?(Class) and Async::Matrix::Versions.api?(value)
    value
  end
end

# Bounded because each iteration derives the classes of every API: a thousand of them costs minutes and says no more than fifty do.
# Kept across the iterations rather than within one, so that an API is reported by the median of every sample taken of it: one sample apiece would be one collection away from saying nothing.
SAMPLES = Hash.new{|samples, name| samples[name] = []}

run_benchmark(maximum: 50) do
  NAMESPACES.each do |namespace|
    Async::Matrix::Versions.instance_variable_set(:@apis, nil)

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Async::Matrix::Versions[VERSION, namespace]

    SAMPLES[namespace.name] << Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  {per_namespace: SAMPLES.transform_values{|samples| median(samples)}}
end
