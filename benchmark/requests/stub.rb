# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# A homeserver which does nothing, so that what is measured is this library rather than Synapse.
#
# The point of an async client is that it can be waiting for many responses at once. Measuring that against a real homeserver does not work: Synapse answers a request at a time, so sixty-four concurrent requests to it come back no faster than sixty-four sequential ones, and the number produced describes Synapse's concurrency rather than ours. The first attempt at this measured exactly that and read 1.03x, which says nothing about this library at all.
#
# So the server here answers every request after a fixed delay and does no work. The delay is the whole point: concurrency does not make a response arrive sooner, it makes the waiting overlap, so a server which answers instantly has nothing to overlap and would show a flat curve however good the client is. Five milliseconds is roughly what a homeserver on the same machine costs.
#
# It binds an ephemeral port rather than a chosen one. An early version used a fixed port which turned out to be published by the rig's compose file, so Synapse answered the requests and the results looked plausible - hence `answered_by`, which every benchmark here checks before it believes a number.
#
# Not a benchmark, and not listed in benchmarks.yml.

require "async"
require "async/http/server"
require "async/http/endpoint"

require "async/matrix"

# A homeserver which does nothing but wait.
module Stub
  # What the stub says when asked which versions it supports, which is how a benchmark tells it apart from a real homeserver.
  IDENTITY = "stub"

  # How long the stub takes to answer, in seconds. Concurrency hides waiting, so there has to be some.
  DELAY = Float(ENV.fetch("STUB_DELAY", 0.005))

  class << self
    # Run a stub, hand a client for it to the block, and take it down afterwards.
    def run
      Sync do |task|
        endpoint = ::Async::HTTP::Endpoint.parse("http://127.0.0.1:0")
        bound = endpoint.bound

        # A BoundEndpoint knows neither, and the server asks the endpoint for both:
        server = ::Async::HTTP::Server.new(self.application, bound, protocol: endpoint.protocol, scheme: endpoint.scheme)
        serving = task.async{server.run}

        client = Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(self.address(bound))

        begin
          yield client
        ensure
          client.close
          serving.stop
          bound.close
        end
      end
    end

    # Whether the client is talking to the stub, rather than to something else which happened to be listening.
    def answered_by_stub?(client)
      client.versions.versions == [IDENTITY]
    end

    private

    # Where the stub ended up, which it was not told and had to be asked.
    def address(bound)
      "http://127.0.0.1:#{bound.sockets.first.local_address.ip_port}"
    end

    # Everything a benchmark here asks for, answered after the delay and with no work done.
    def application
      ::Protocol::HTTP::Middleware.for do |request|
        sleep(DELAY)

        ::Protocol::HTTP::Response[200, {"content-type" => "application/json"}, [%({"versions":["#{IDENTITY}"]})]]
      end
    end
  end
end
