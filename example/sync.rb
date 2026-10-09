#!/usr/bin/env ruby
# frozen_string_literal: true

# Read messages off a homeserver with Client#sync.
#
#   docker compose up -d
#   ruby sync.rb
#
# Logs in as @alice:localhost (any password works -- see
# synapse/modules/any_password.py), then prints every message that arrives.
# The first batch is the full state of every room the account is in, so a
# fresh account starts quiet and everything printed after that is live.
# To see something, log in as anyone else in a client pointed at
# http://localhost:8008, invite @alice:localhost to a room, and talk.

require "async"
require "async/matrix"

HOMESERVER = ENV.fetch("HOMESERVER", "http://localhost:8008")
USERNAME   = ENV.fetch("MATRIX_USER", "alice")
PASSWORD   = ENV.fetch("MATRIX_PASSWORD", "any-password-will-do")

# Client reads exactly two fields off its config, so a config is cheap to build
# by hand -- no YAML file needed.
def config_for(token)
  Async::Matrix::Config.new(
    {
      "homeserver" => {"address" => HOMESERVER, "domain" => "localhost"},
      "appservice" => {"as_token" => token},
    },
  )
end

Async do
  # /login is the one call made without a token, so the bootstrap client carries
  # an empty one.
  session = Async::Matrix::Client.new(config_for("")).api.login.post(
    {
      type:       "m.login.password",
      identifier: {type: "m.id.user", user: USERNAME},
      password:   PASSWORD,
    },
  )

  client = Async::Matrix::Client.new(config_for(session["access_token"]))
  Console.info("Logged in as #{session["user_id"]}.")

  Console.info("Syncing. Waiting for messages...")

  # Loops forever: one long poll per batch, each resumed from the cursor the
  # last one returned. No store is passed because this rig creates unencrypted
  # rooms, so there is nothing to decrypt.
  client.sync do |events|
    events.each do |event|
      if event.type == "m.room.message"
        Console.info(
          "#{event.sender}: #{event.content.body}",
          room: event.room_id,
        )
      end
    end
  end
end
