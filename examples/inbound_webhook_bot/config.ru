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

bot = Async::Matrix::ApplicationService::Bot.new(client) do
  on "m.room.member" do |event|
    if event.content.membership == "invite" &&
       event.state_key == client.config.bot_mxid

      Console.info(self) { "Invited to #{event.room_id} by #{event.sender} — joining" }
      join_room(event.room_id)
    end
  end
end

server = Async::Matrix::ApplicationService::Server.new(
  hs_token: config.appservice.hs_token
)
server.register(bot)

Console.info(self) { "Bot MXID: #{config.bot_mxid}" }
Console.info(self) { "Homeserver: #{config.homeserver.address}" }
Console.info(self) { "Webhook endpoint: POST /_webhook/send" }

# --- Webhook handler -----------------------------------------------------
#
# POST /_webhook/send with JSON body:
#   { "room_id": "!room:localhost", "body": "message text" }

webhook_app = ->(env) {
  req = Rack::Request.new(env)
  body = JSON.parse(req.body.read)
  client.send_text(body["room_id"], body["body"])
  [200, {"content-type" => "application/json"}, ['{"ok":true}']]
}

# --- Composite app -------------------------------------------------------
#
# Routes /_webhook/send to the webhook handler, everything else to the
# Application Service server (which handles /_matrix/app/v1/* routes).

app = ->(env) {
  if env["PATH_INFO"] == "/_webhook/send" && env["REQUEST_METHOD"] == "POST"
    webhook_app.call(env)
  else
    server.call(env)
  end
}

run app
