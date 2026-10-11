# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# A client for the homeserver bin/benchmark brought up, which is the rig the suite runs against.
#
# What these benchmarks measure is the whole system - this library, the socket, and a real homeserver doing real work - so a figure from one is not a figure about this library alone. That is the point of having them: the per-message and per-version costs are measured elsewhere, and what is left is whether the thing works at the speed anybody would want end to end.
#
# A figure here therefore moves when Synapse changes, when the image changes, and when the machine is busy, and should not be read as a regression in this library without checking the rest first. They are opt-in for that reason: bin/benchmark leaves them out unless they are asked for.
#
# The account dance is the fixtures' dance, for the same reason: the synapse rig registers a user on first login, and the tuwunel rig needs the account registered first. bin/benchmark says which through MATRIX_ACCOUNTS, exactly as bin/test does for the suite.
#
# Not a benchmark, and not listed in benchmarks.yml.

require "securerandom"

require "async"

require "async/matrix"

# A client for the homeserver under test.
module Rig
  # Where the homeserver is, which is where the rig's compose file publishes it.
  HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:7300")

  # The version under test, as the suite reads it.
  VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

  # How to get an account: `login` where the rig registers one on first login, `register` where it must be asked first.
  ACCOUNTS = ENV.fetch("MATRIX_ACCOUNTS", "login")

  PASSWORD = "password"

  class << self
    # Open a client for the homeserver, hand it to the block, and close it afterwards.
    def run
      Sync do
        client = Async::Matrix::ClientServer::Client[VERSION].open(HOMESERVER)

        begin
          yield client
        ensure
          client.close
        end
      end
    end

    # An authenticated client, for a user nobody else is using.
    def account(client)
      username = "benchmark-#{SecureRandom.hex(6)}"

      if ACCOUNTS == "register"
        client.registration.register(username: username, password: PASSWORD, auth: {type: "m.login.dummy"}, inhibit_login: true)
      end

      client.logged_in(username, PASSWORD)
    end
  end
end
