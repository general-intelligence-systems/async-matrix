# frozen_string_literal: true

# Echo Bot — Rack entry point
# Run with: falcon serve --bind http://0.0.0.0:9292

require "bundler/setup"
require "async/matrix"
require_relative "handlers/invite"
require_relative "handlers/message"

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

dispatcher =
  Async::Matrix::ApplicationService::Dispatcher.new.tap do |d|
    d.register(EchoBot::Handlers::Invite.new(client))
    d.register(EchoBot::Handlers::Message.new(client))
  end

Console.info(self) { "Handlers registered: #{dispatcher.handler_count}" }
Console.info(self) { "Bot MXID: #{config.bot_mxid}" }
Console.info(self) { "Homeserver: #{config.homeserver.address}" }

app =
  Async::Matrix::ApplicationService::Server.new(
    hs_token:   config.appservice.hs_token,
    dispatcher: dispatcher
  )

run app
