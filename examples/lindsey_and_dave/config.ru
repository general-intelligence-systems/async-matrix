# frozen_string_literal: true

# Lindsey & Dave — Two bots, one appservice
# Run with: falcon serve --bind http://0.0.0.0:9292

require "bundler/setup"
require "async/matrix"

Bot    = Async::Matrix::ApplicationService::Bot
Config = Async::Matrix::ApplicationService::Config
Server = Async::Matrix::ApplicationService::Server
Client = Async::Matrix::Client

config = Config.load(
  ENV.fetch("APPSERVICE_CONFIG", File.join(__dir__, "config/appservice.yml"))
)

lindsey = Bot.new(Client.new(config)) do
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

dave = Bot.new(Client.new(config)) do
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

app = Server.new(hs_token: config.appservice.hs_token)
app.register(lindsey)
app.register(dave)

Console.info(self) { "Homeserver: #{config.homeserver.address}" }
Console.info(self) { "Bot MXID:   #{config.bot_mxid}" }

run app
