# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require "async/matrix"

# What it costs to build the classes for one version, which is what making the first client of a version pays.
#
# A version is built by deriving a class per versioned class and including a layer per version up to it, so the work is the number of classes times the number of layers.

# The version built, passed through by bin/benchmark as it is for the suite.
VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

# The API built, which is the largest of them.
NAMESPACE = Async::Matrix::ClientServer

# The built classes are cached on {Async::Matrix::Versions}, so the cache is cleared to measure the building rather than the lookup. Reaching for the ivar is the only way in: there is no public way to forget a version, and nothing outside a benchmark would want one.
#
# Bounded because each iteration derives a hundred and forty-five classes: a thousand of them costs seconds and says no more than fifty do.
run_benchmark(maximum: 50) do
  Async::Matrix::Versions.instance_variable_set(:@apis, nil)

  api = Async::Matrix::Versions[VERSION, NAMESPACE]

  {
    constants: api.constants.size,
    classes: Async::Matrix::Versions.classes(NAMESPACE).size,
    layers: Async::Matrix::Versions.layers_for(VERSION).size,
  }
end
