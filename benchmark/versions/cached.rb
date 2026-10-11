# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require "async/matrix"

# What a version costs once it has been built, which is what every client after the first pays.
#
# The cache is the whole of the claim that a client is cheap to make, so this is the benchmark which fails loudly if the key ever stops matching: against the build it should be nothing at all. Worth running under the ips harness, where a rate is the number that reads.

# The version looked up, passed through by bin/benchmark as it is for the suite.
VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

# The API looked up, which is the largest of them.
NAMESPACE = Async::Matrix::ClientServer

# Built once here rather than in the measurement, which is what makes this the lookup and not the build:
Async::Matrix::Versions[VERSION, NAMESPACE]

run_benchmark do
  Async::Matrix::Versions[VERSION, NAMESPACE]
end
