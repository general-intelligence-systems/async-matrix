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
require "anthropic"

Bot    = Async::Matrix::ApplicationService::Bot
Config = Async::Matrix::ApplicationService::Config
Server = Async::Matrix::ApplicationService::Server
Client = Async::Matrix::Client

MODEL = ENV.fetch("BRUTE_MODEL", "claude-sonnet-4-20250514")

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

bot_client = Client.new(config)

# Advertise Brute's tools as Anthropic tool definitions.
def anthropic_tools(tools)
  Brute.tools(tools).values.map do |adapter|
    defn = adapter.to_h
    {name: defn[:name], description: defn[:description], input_schema: defn[:parameters]}
  end
end

# Brute 3.x is framework-agnostic: the terminal `run` proc owns the LLM call and
# all LLM configuration. Brute::MessageTransport::Anthropic translates the
# message log to/from the official anthropic gem's Messages API. The ToolPipeline
# advertises tools and runs them; Loop::ToolResult loops until the agent stops.
agent = Brute.agent
  .use(Brute::Middleware::SystemPrompt)
  .use(Brute::Middleware::Loop::ToolResult)
  .use(Brute::Middleware::MaxIterations)
  .use(Brute::Middleware::ToolPipeline, tools: Brute::Tools::ALL)
  .run do |env|
    client    = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    transport = Brute::MessageTransport::Anthropic

    params = {
      model:      MODEL,
      max_tokens: 16_000,
      messages:   transport.dump_all(env[:messages]),
    }
    system_text = transport.system_text(env[:messages])
    params[:system_] = system_text unless system_text.empty?

    tools = anthropic_tools(env[:tools])
    params[:tools] = tools unless tools.empty?

    response = client.messages.create(**params)
    transport.wrap_each(response) { |message| env[:messages] << message }
  end

# --- Matrix Bot -----------------------------------------------------

# The block form of `dispatch` builds a Bot from the configured `client:`, so
# handler blocks get helpers like `join_room` and `send_notice`.
app =
  Server.new(hs_token: config.appservice.hs_token, client: bot_client) do
    dispatch do
      on "m.room.member" do |event|
        if event.content.membership == "invite" &&
           event.state_key == bot_client.config.bot_mxid
          Console.info(self) { "Invited to #{event.room_id} by #{event.sender} — joining" }
          join_room(event.room_id)
        end
      end

      on "m.room.message", msgtype: "m.text", not_from: :self do |event|
        Console.info(self) {
          "Message from #{event.sender} in #{event.room_id}: #{event.content.body[0..100]}"
        }

        log = Brute.log
        log.user(event.content.body)
        env = agent.start(log)

        response = env[:messages].select { |m| m.role == :assistant && m.content.present? }.last

        if response
          send_notice(event.room_id, response.content)
        else
          Console.warn(self) { "Agent produced no text response for: #{event.content.body[0..60]}" }
        end
      end
    end
  end

Console.info(self) { "Brute Matrix Bot starting..." }
Console.info(self) { "Bot MXID:    #{config.bot_mxid}" }
Console.info(self) { "Homeserver:  #{config.homeserver.address}" }
Console.info(self) { "Model:       #{MODEL}" }

run app
