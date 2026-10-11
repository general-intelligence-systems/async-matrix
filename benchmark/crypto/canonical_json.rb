# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require "async/matrix/e2ee/canonical_json"

require_relative "subject"

# Rendering an event in the form it is signed and hashed in, which every signature and every verification starts with.
#
# Sorting the keys and walking the whole object is pure Ruby, done once per signature and twice per round trip, so it sits under everything else in this directory. If signing ever looks slower than Ed25519 should be, this is where to look first.

run_benchmark do
  Async::Matrix::E2EE::CanonicalJSON.for_signing(Subject::EVENT)
end
