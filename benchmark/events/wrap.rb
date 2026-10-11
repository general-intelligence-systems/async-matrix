# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require "async/matrix/events"

require_relative "payload"

# What it costs to turn a batch of decoded events into objects, which is the work a client does per message rather than per request.
#
# A sync response carries hundreds of events and each one is dispatched onto a class and wrapped in an envelope, so this is the path which is walked most often in the whole library. The batch is one event of every type the version describes, which is a harder mix than a real timeline - a real one is mostly messages - and therefore a fair upper bound on the dispatch.

# The version decoded, passed through by bin/benchmark as it is for the suite.
VERSION = ENV.fetch("MATRIX_VERSION"){Async::Matrix::LATEST}

REGISTRY = Async::Matrix::Events.registry(VERSION)

EVENTS = Payload.events(VERSION).freeze

ROOM_ID = :"!benchmark:example.com"

run_benchmark do
  EVENTS.each do |event|
    REGISTRY.wrap(event, room_id: ROOM_ID)
  end

  {events: EVENTS.size}
end
