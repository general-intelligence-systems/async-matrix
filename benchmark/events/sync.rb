# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require "json"

require "async/matrix/events"

require_relative "payload"

# What a client pays for one sync response: parsing the JSON, walking it, and wrapping every event in it.
#
# The end to end figure for the thing a client does all day, with the homeserver and the network taken out of it. It is the benchmark worth quoting about decoding, and the one to profile when a sync feels slow, because it is the only one here which includes the parse - and the parse may well be the larger half, which is worth knowing before anything is done to the dispatch.

# The version decoded, passed through by bin/benchmark as it is for the suite.
VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

REGISTRY = Async::Matrix::Events.registry(VERSION)

# Serialized once, because what is being measured is a response arriving rather than one being built.
DOCUMENT = JSON.generate(Payload.sync(VERSION)).freeze

run_benchmark do
  sync = JSON.parse(DOCUMENT, symbolize_names: true)
  decoded = 0

  sync[:rooms][:join].each do |room_id, room|
    [room[:timeline][:events], room[:state][:events]].each do |events|
      events.each do |event|
        REGISTRY.wrap(event, room_id: room_id)

        decoded += 1
      end
    end
  end

  {events: decoded, bytes: DOCUMENT.bytesize}
end
