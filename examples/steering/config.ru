# frozen_string_literal: true

# Steering Bot — Async Matrix bot with PicoClaw-style message steering
#
# Extends the brute example with two key capabilities:
#
#   1. Per-room conversation memory — each Matrix room maintains a
#      persistent Brute::Session across turns, so the agent sees the
#      full conversation history.
#
#   2. Steering — when a user sends a message while the agent is still
#      processing a previous one, the new message is queued and injected
#      into the running agent loop between tool iterations. The agent
#      sees the interruption in context and can adjust its response.
#
# This is modeled on PicoClaw's steering queue architecture:
#
#   - activeTurnStates.LoadOrStore → active_rooms[room_id] claim
#   - steeringQueue.pushScope      → steering[room_id] << content
#   - dequeueSteeringMessages      → SteeringCheck middleware drains the queue
#   - Continue() post-turn loop    → drain loop after agent.call returns
#
# No mutexes are needed. Falcon runs fibers cooperatively on a single
# thread — a fiber only yields at I/O boundaries (HTTP calls, sleep).
# In-memory hash operations are never interrupted.
#
# Run with: falcon serve --bind http://0.0.0.0:9292

require "bundler/setup"
require "async/matrix"
require "brute"
require_relative "steering_check"

Bot    = Async::Matrix::ApplicationService::Bot
Config = Async::Matrix::ApplicationService::Config
Server = Async::Matrix::ApplicationService::Server
Client = Async::Matrix::Client

# --- Configuration --------------------------------------------------

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

# --- Shared State ---------------------------------------------------
#
# These are plain Hashes. Fiber-safe without synchronization because
# Falcon's cooperative scheduler never preempts in-memory operations.
#
# sessions      — { room_id => Brute::Session } per-room conversation history
# active_rooms  — { room_id => true }            rooms with an active agent turn
# steering      — { room_id => [String, ...] }   queued messages for busy rooms

sessions     = {}
active_rooms = {}
steering     = {}

# --- Agent Pipeline -------------------------------------------------
#
# The middleware stack mirrors the brute example but inserts SteeringCheck
# between ToolResultLoop and MaxIterations. This is the checkpoint where
# queued messages are drained and injected — equivalent to PicoClaw's
# dequeueSteeringMessages call after each tool execution.
#
#   EventHandler       — routes pipeline events to terminal output
#   SystemPrompt       — prepends the system prompt on iteration 1
#   ToolResultLoop     — re-invokes inner stack while tool results are pending
#   ┌─ SteeringCheck   — drains steering queue, injects as :user messages
#   │  MaxIterations   — guards against runaway loops
#   │  ToolCall         — executes tool calls concurrently via Async::Barrier
#   └─ LLMCall          — terminal: calls the LLM API

agent = Brute::Agent.new(
  provider: Brute.provider,
  model:    ENV.fetch("BRUTE_MODEL", "claude-sonnet-4-20250514"),
  tools:    [],
) do
  use Brute::Middleware::EventHandler, handler_class: Brute::Events::TerminalOutput
  use Brute::Middleware::SystemPrompt
  use Brute::Middleware::ToolResultLoop
  use SteeringCheck, steering: steering
  use Brute::Middleware::MaxIterations
  use Brute::Middleware::ToolCall
  run Brute::Middleware::LLMCall.new
end

# --- Helpers --------------------------------------------------------

# Run an agent turn and return the last assistant response content.
# Fiber[:room_id] is already set by the handler fiber before this is called,
# so SteeringCheck can find the right queue during the pipeline.
run_turn = ->(session) do
  agent.call(session)
  session.select { |m| m.role == :assistant && m.content.present? }.last
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
    room_id = event.room_id
    content = event.content.body

    Console.info(self) {
      "Message from #{event.sender} in #{room_id}: #{content[0..100]}"
    }

    # --- Session claim (PicoClaw's LoadOrStore pattern) ---
    #
    # Try to claim the room. If another fiber already owns it, enqueue
    # the message as steering instead. No race is possible — the check
    # and store are in-memory operations with no yield point between them.

    if active_rooms[room_id]
      # Room is busy — enqueue as steering message.
      if SteeringCheck.enqueue(steering, room_id, content)
        Console.info(self) {
          "Steering enqueued for #{room_id} (queue depth: #{steering[room_id]&.size})"
        }
      else
        Console.warn(self) {
          "Steering queue full for #{room_id} — dropping message"
        }
      end
      next
    end

    # Claim the room and set the fiber-local room_id so SteeringCheck
    # can find the right queue during the pipeline.
    active_rooms[room_id] = true
    Fiber[:room_id] = room_id

    begin
      session = (sessions[room_id] ||= Brute::Session.new)
      session.user(content)

      response = run_turn.call(session)
      send_notice(room_id, response.content) if response

      # --- Post-turn drain loop (PicoClaw's Continue pattern) ---
      #
      # After the turn completes, drain any steering messages that
      # arrived during processing. Each batch starts a new turn so
      # the agent sees the full accumulated context.
      #
      # This loop runs in the same fiber that claimed the room, so
      # active_rooms[room_id] remains set throughout — any messages
      # arriving during these continuation turns are also enqueued
      # as steering.

      while steering[room_id]&.any?
        messages = steering[room_id].dup
        steering[room_id].clear

        messages.each { |c| session.user(c) }

        response = run_turn.call(session)
        send_notice(room_id, response.content) if response
      end

    ensure
      active_rooms.delete(room_id)
      steering.delete(room_id)
    end
  end
end

# --- Server ---------------------------------------------------------

app = Server.new(hs_token: config.appservice.hs_token)
app.register(bot)

Console.info(self) { "Steering Bot starting..." }
Console.info(self) { "Bot MXID:    #{config.bot_mxid}" }
Console.info(self) { "Homeserver:  #{config.homeserver.address}" }
Console.info(self) { "Provider:    #{Brute.provider}" }
Console.info(self) { "Model:       #{ENV.fetch("BRUTE_MODEL", "claude-sonnet-4-20250514")}" }

run app
