# frozen_string_literal: true

# Lindsey & Dave — Two bots, one appservice
# Run with: falcon serve --bind http://0.0.0.0:9292

require "bundler/setup"
require "async/matrix"

Bot    = Async::Matrix::ApplicationService::Bot
Config = Async::Matrix::ApplicationService::Config
Server = Async::Matrix::ApplicationService::Server
Client = Async::Matrix::Client

shared = {
  "homeserver" => {
    "address" => "http://synapse:8008",
    "domain"  => "localhost",
  },
  "appservice" => {
    "as_token" => "956a8cd58dd8420649717fade3974590641594a8f59989c2c00b1e68a427a56a",
    "hs_token" => "51013f109db594670d083539775bae41fdae8da9aae53df115906b957ef60464",
    "hostname" => "0.0.0.0",
    "port"     => 9292,
  }
}

lindsey_config = Config.new(shared.merge(
  "appservice" => shared["appservice"].merge("bot" => { "username" => "lindsey" })
))

dave_config = Config.new(shared.merge(
  "appservice" => shared["appservice"].merge("bot" => { "username" => "dave" })
))

lindsey = Bot.new(Client.new(lindsey_config)) do
  on "m.room.member" do |event|
    if event.content.membership == "invite" &&
       event.state_key == client.config.bot_mxid
      join_room(event.room_id)
    end
  end

  on "m.room.message", msgtype: "m.text", not_from: :self do |event|
    body = event.content.body

    case body.downcase
    when /\bhello\b/, /\bhi\b/, /\bhey\b/
      send_notice event.room_id, "Hey there! I'm Lindsey. Nice to meet you!"
    when /\bhelp\b/
      send_notice event.room_id, "I'm Lindsey, the greeter bot. Say hello and I'll say hi back!"
    end
  end
end

dave = Bot.new(Client.new(dave_config)) do
  on "m.room.member" do |event|
    if event.content.membership == "invite" &&
       event.state_key == client.config.bot_mxid
      join_room(event.room_id)
    end
  end

  on "m.room.message", msgtype: "m.text", not_from: :self do |event|
    send_notice event.room_id, "Dave heard: #{event.content.body}"
  end
end

app = Server.new(hs_token: lindsey_config.appservice.hs_token)
app.register(lindsey)
app.register(dave)

Console.info(self) { "Homeserver: #{lindsey_config.homeserver.address}" }
Console.info(self) { "Lindsey MXID: #{lindsey_config.bot_mxid}" }
Console.info(self) { "Dave MXID:    #{dave_config.bot_mxid}" }

run app
