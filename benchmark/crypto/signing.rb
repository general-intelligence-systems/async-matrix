# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require_relative "subject"

# Signing an event, which a homeserver does to everything it sends and everything it creates.
#
# Canonical JSON and then Ed25519 over the result, so the difference between this and crypto/canonical_json is what the signature itself costs.

run_benchmark do
  Subject::KEY.sign(Subject::EVENT)
end
