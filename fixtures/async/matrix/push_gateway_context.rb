# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "sus/fixtures/async"

require "async/matrix"

require_relative "client_context"

module Async
  module Matrix
    # Where the push gateway is.
    #
    # The rig runs sygnal, which `bin/test --api push-gateway` brings up. It has one application configured because it will not start without one, and nothing is pushed to it: see synapse/sygnal.yaml.
    PUSH_GATEWAY = ENV.fetch("MATRIX_PUSH_GATEWAY", "http://localhost:7303")

    # An application the gateway does not know, so that a notification is rejected rather than sent.
    PUSH_APPLICATION = "com.example.unknown"

    # Included by a test which exercises the push gateway API.
    #
    # The client is called `unauthenticated` because that is the name {OperationsContext} spies on to prove a case made a request, and because a gateway has nothing to authenticate with.
    PushGatewayContext = Sus::Shared("a push gateway client") do
      include Sus::Fixtures::Async::ReactorContext

      let(:unauthenticated) {Async::Matrix::PushGateway::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::PUSH_GATEWAY)}

      # One device to push to, which names an application the gateway does not know.
      let(:device) {{app_id: Async::Matrix::PUSH_APPLICATION, pushkey: "a-push-key", pushkey_ts: 1, data: {}}}

      # An event worth a notification, as a homeserver would describe it.
      let(:notification) do
        {
          event_id: "$an-event",
          room_id: "!a-room:localhost",
          type: "m.room.message",
          sender: "@someone:localhost",
          counts: {unread: 1},
          devices: [device],
        }
      end
    end
  end
end
