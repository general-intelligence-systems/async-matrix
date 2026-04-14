# frozen_string_literal: true

# Echo Bot — Rack entry point
# Run with: falcon serve --bind http://0.0.0.0:9292

require_relative "../../lib/matrix"
require_relative "config"
require_relative "transaction_store"
require_relative "client"
require_relative "dispatcher"
require_relative "server"
require_relative "handlers/invite"
require_relative "handlers/message"

# ── Load configuration ─────────────────────────────────────────
config_path = ENV.fetch("APPSERVICE_CONFIG", File.join(__dir__, "config/appservice.yml"))
config = EchoBot::Config.load(config_path)

# ── Build the client (outbound Matrix CS API) ─────────────────
client = EchoBot::Client.new(config)

# ── Build the dispatcher and register handlers ────────────────
dispatcher = EchoBot::Dispatcher.new
dispatcher.register(EchoBot::Handlers::Invite.new(client))
dispatcher.register(EchoBot::Handlers::Message.new(client))

Matrix.logger.info { "Handlers registered: #{dispatcher.handler_count}" }
Matrix.logger.info { "Bot MXID: #{config.bot_mxid}" }
Matrix.logger.info { "Homeserver: #{config.homeserver_url}" }

# ── Mount the Rack app ────────────────────────────────────────
app = EchoBot::Server.new(
  hs_token:   config.hs_token,
  dispatcher: dispatcher
)

run app
