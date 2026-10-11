# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require "async/matrix/events"

# What it costs to build the registry for a version, which a program pays once per API it decodes with.
#
# Building one walks every constant of the generated events, asks each whether it carries a type, and files it under that type and its variant. It is the event half of what versions/build measures, and it is paid on the first event decoded rather than when the client is made.

# The version built, passed through by bin/benchmark as it is for the suite.
VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

# Built here rather than in the measurement, so that what is measured is the registry rather than the classes it files.
API = Async::Matrix::Events[VERSION]

# The registries are cached by API, so the cache is cleared to measure the building rather than the lookup. Reaching for the ivar is the only way in: nothing outside a benchmark would want to forget one.
run_benchmark(maximum: 100) do
  Async::Matrix::Events::Registry.instance_variable_set(:@registries, nil)

  registry = Async::Matrix::Events::Registry.for(API)

  {types: registry.types.size}
end
