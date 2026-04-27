# frozen_string_literal: true

# Echo Bot — Rack entry point
# Run with: falcon serve --bind http://0.0.0.0:9292

require_relative "../../lib/async/matrix"
require_relative "handlers/invite"
require_relative "handlers/message"

# ── Load configuration ─────────────────────────────────────────
config_path = ENV.fetch("APPSERVICE_CONFIG", File.join(__dir__, "config/appservice.yml"))
config = Async::Matrix::ApplicationService::Config.load(config_path)

# ── Build the client (outbound Matrix CS API) ─────────────────
client = Async::Matrix::Client.new(config)

# ── Build the dispatcher and register handlers ────────────────
dispatcher = Async::Matrix::ApplicationService::Dispatcher.new
dispatcher.register(EchoBot::Handlers::Invite.new(client))
dispatcher.register(EchoBot::Handlers::Message.new(client))

Console.info(self) { "Handlers registered: #{dispatcher.handler_count}" }
Console.info(self) { "Bot MXID: #{config.bot_mxid}" }
Console.info(self) { "Homeserver: #{config.homeserver_url}" }

# ── Mount the Rack app ────────────────────────────────────────
app = Async::Matrix::ApplicationService::Server.new(
	hs_token:   config.hs_token,
	dispatcher: dispatcher
)

run app
