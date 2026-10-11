# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require_relative "rig"

# One unauthenticated request against a real homeserver, end to end.
#
# The cheapest thing a homeserver will answer, so what is left in the figure is the socket, the wrapper, and the parse rather than anything the homeserver had to think about. It is the floor under every other request: nothing this library does can be faster than this.

Rig.run do |client|
  run_benchmark do
    client.versions
  end
end
