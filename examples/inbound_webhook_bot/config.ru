# frozen_string_literal: true

# Inbound Webhook Bot — Rack entry point
#
# Exposes a webhook endpoint alongside the standard Matrix Application Service
# API. External systems can POST to /_webhook/send to have the bot send a
# message into a Matrix room.
#
# Usage:
#   curl -X POST http://localhost:9292/_webhook/send \
#     -H "Content-Type: application/json" \
#     -d '{"room_id": "!abc:localhost", "body": "hello from outside"}'
#
# Run with: falcon serve --bind http://0.0.0.0:9292

require "bundler/setup"
require "async/matrix"
require "json"
require "rack"

config = Async::Matrix::ApplicationService::Config.new(
  "homeserver" => {
    "address" => "http://synapse:8008",
    "domain"  => "localhost",
  },
  "appservice" => {
    "as_token" => "956a8cd58dd8420649717fade3974590641594a8f59989c2c00b1e68a427a56a",
    "hs_token" => "51013f109db594670d083539775bae41fdae8da9aae53df115906b957ef60464",
    "bot"      => { "username" => "bot" },
    "hostname" => "0.0.0.0",
    "port"     => 9292,
  }
)

client = Async::Matrix::Client.new(config)

webhook_client = client

Console.info(self) { "Bot MXID: #{config.bot_mxid}" }
Console.info(self) { "Homeserver: #{config.homeserver.address}" }
Console.info(self) { "Webhook endpoint: POST /_webhook/send" }

# --- Application Service + custom endpoint -------------------------------
#
# The Server forwards the Grape route DSL, so an app-specific endpoint can be
# declared right in the block, on the same Grape::API as the Matrix routes. The
# homeserver auth filter is scoped to the Matrix routes only, so the webhook
# below is independent of Matrix auth. Inside an endpoint, `client` is the
# Client passed as `client:` above.
#
# POST /_webhook/send with JSON body:
#   { "room_id": "!room:localhost", "body": "message text" }

app =
  Async::Matrix::ApplicationService::Server.new(
    hs_token: config.appservice.hs_token,
    client:   webhook_client
  ) do
    dispatch do
      on "m.room.member" do |event|
        if event.content.membership == "invite" &&
           event.state_key == webhook_client.config.bot_mxid

          Console.info(self) { "Invited to #{event.room_id} by #{event.sender} — joining" }
          join_room(event.room_id)
        end
      end
    end

    post "/_webhook/send" do
      client.send_text(params[:room_id], params[:body])
      {ok: true}
    end
  end

run app
