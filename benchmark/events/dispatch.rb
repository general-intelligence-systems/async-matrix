# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require "async/matrix/events"

# What it costs to decide which class an event is, for the type where deciding is hardest.
#
# A type's variants are held in a hash and scanned in turn, each one comparing every field which distinguishes it, so the cost of a dispatch is the number of variants ahead of the match rather than a lookup. The type with the most of them, matched on the last, is therefore the longest scan the registry does: if variant dispatch is ever worth indexing, this is the benchmark which would say so.
#
# Nothing is returned from the block. A single dispatch is a matter of microseconds, and building a hash to report alongside it would cost more than the thing being measured.

# The version decoded, passed through by bin/benchmark as it is for the suite.
VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

REGISTRY = Async::Matrix::Events.registry(VERSION)

# The type with the most variants, and the content which matches the last of them.
TYPE, ENTRY = REGISTRY.types.max_by{|_, entry| entry[:variants].size}

CONTENT = ENTRY[:variants].keys.last.merge(body: "benchmark").freeze

run_benchmark do
  REGISTRY.content_class(TYPE, CONTENT)
end
