# frozen_string_literal: true

# Brute Agent Bot — Rack entry point
#
# A Matrix bot powered by a Brute coding agent. Every message sent to the
# bot is forwarded to the agent as a fresh session. The agent can read and
# write files, run shell commands, search code, and more — then its final
# text response is sent back to the Matrix room.
#
# Run with: falcon serve --bind http://0.0.0.0:9292

require "bundler/setup"
require "async/matrix"
require "brute"

Bot    = Async::Matrix::ApplicationService::Bot
Config = Async::Matrix::ApplicationService::Config
Server = Async::Matrix::ApplicationService::Server
Client = Async::Matrix::Client

config = Config.new(
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

client = Client.new(config)

agent = Brute::Agent.new(
  provider: Brute.provider,
  model:    ENV.fetch("BRUTE_MODEL", "claude-sonnet-4-20250514"),
  tools:    [],
) do
  use Brute::Middleware::EventHandler, handler_class: Brute::Events::TerminalOutput
  use Brute::Middleware::SystemPrompt
  run Brute::Middleware::LLMCall.new
end

# --- Matrix Bot -----------------------------------------------------

bot = Bot.new(client) do
  on "m.room.member" do |event|
    if event.content.membership == "invite" &&
       event.state_key == client.config.bot_mxid
      Console.info(self) { "Invited to #{event.room_id} by #{event.sender} — joining" }
      join_room(event.room_id)
    end
  end

  on "m.room.message", msgtype: "m.text", not_from: :self do |event|
    Console.info(self) {
      "Message from #{event.sender} in #{event.room_id}: #{event.content.body[0..100]}"
    }

    session = Brute::Session.new
    session.user(event.content.body)
    agent.call(session)

    response = session.select { |m| m.role == :assistant && m.content.present? }.last

    if response
      send_notice(event.room_id, response.content)
    else
      Console.warn(self) { "Agent produced no text response for: #{event.content.body[0..60]}" }
    end
  end
end

# --- Server ---------------------------------------------------------

app = Server.new(hs_token: config.appservice.hs_token)
app.register(bot)

Console.info(self) { "Brute Matrix Bot starting..." }
Console.info(self) { "Bot MXID:    #{config.bot_mxid}" }
Console.info(self) { "Homeserver:  #{config.homeserver.address}" }
Console.info(self) { "Provider:    #{Brute.provider}" }
Console.info(self) { "Model:       #{ENV.fetch("BRUTE_MODEL", "claude-sonnet-4-20250514")}" }

run app
