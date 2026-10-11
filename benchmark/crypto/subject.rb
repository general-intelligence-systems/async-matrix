# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# The key and the event the crypto benchmarks work on.
#
# A room event of about the size a real one is: a text message, five previous events, four auth events, and the signature and unsigned fields which canonical JSON drops before signing. Shared so that the four benchmarks here are all measured against the same object and can be read against each other.
#
# The seed is fixed rather than random. Signing is the same work whatever the bytes are, and a benchmark whose input changes between runs cannot be compared against another run - which is the whole point of bin/benchmark --compare.
#
# Nothing here is secret: it is a key generated for a benchmark to sign a message that says "benchmark".
#
# Not a benchmark, and not listed in benchmarks.yml.

require "async/matrix/server_key"
require "async/matrix/middleware/signed"

# The key and the event the crypto benchmarks work on.
module Subject
  # Thirty two bytes which are not anybody's key.
  SEED = ("async-matrix benchmark seed, no" + "t").b

  KEY = Async::Matrix::ServerKey.new("benchmark", SEED)

  ORIGIN = "origin.example.com"

  DESTINATION = "destination.example.com"

  # A room event of about the size a real one is.
  EVENT = {
    type: "m.room.message",
    room_id: "!benchmark:example.com",
    sender: "@benchmark:example.com",
    origin_server_ts: 1_760_000_000_000,
    depth: 42,
    content: {msgtype: "m.text", body: "benchmark " * 20},
    prev_events: (1..5).map{|index| "$prev#{index}benchmark0000000000000000000"},
    auth_events: (1..4).map{|index| "$auth#{index}benchmark0000000000000000000"},

    # Dropped before signing, which is work the canonicaliser does and is therefore part of the measurement:
    signatures: {ORIGIN => {"ed25519:benchmark" => "not the signature under test"}},
    unsigned: {age: 12},
  }.freeze

  # The signature of EVENT, for the benchmark which verifies rather than signs.
  SIGNATURE = KEY.sign(EVENT)

  class << self
    # A federation request carrying the event, which is what Middleware::Signed signs.
    #
    # Built fresh each time: signing reads the body, and a body which has been read cannot be read again.
    def request
      ::Protocol::HTTP::Request.new(
        "https",
        DESTINATION,
        "PUT",
        "/_matrix/federation/v1/send/benchmark",
        nil,
        ::Protocol::HTTP::Headers.new,
        ::Protocol::HTTP::Body::Buffered.new([::JSON.generate(EVENT)]),
      )
    end

    # The middleware under test, which delegates to nothing because nothing is sent.
    def middleware
      Async::Matrix::Middleware::Signed.new(nil, ORIGIN, KEY, DESTINATION)
    end
  end
end
