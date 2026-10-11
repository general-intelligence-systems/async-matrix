# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require_relative "rig"

# One sync round trip against a real homeserver, which is the request a client spends its life in.
#
# `timeout: 0` so the homeserver answers with what it has rather than holding the connection open: what is wanted is the cost of a batch arriving and being decoded, not the cost of waiting. The companion to events/sync, which measures the decoding of a batch with the homeserver and the socket taken out.

Rig.run do |client|
  account = Rig.account(client)

  run_benchmark do
    account.sync(timeout: 0)
  end
end
