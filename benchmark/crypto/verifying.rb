# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require_relative "subject"

# Verifying a signature, which is what a homeserver does to everything that arrives.
#
# The side that is paid per inbound event rather than per outbound one, and a server receives more than it sends. Ed25519 verification is not symmetric with signing, so this is worth measuring separately rather than assumed from crypto/signing.

run_benchmark do
  Subject::KEY.verify(Subject::EVENT, Subject::SIGNATURE)
end
