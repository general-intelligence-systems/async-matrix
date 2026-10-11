# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require_relative "rig"

# One authenticated request against a real homeserver, end to end.
#
# The same shape as homeserver/versions with the authentication middleware in the way and a homeserver which has to look a token up, so the difference between the two is what being logged in costs.

Rig.run do |client|
  account = Rig.account(client)

  run_benchmark do
    account.get_token_owner
  end
end
