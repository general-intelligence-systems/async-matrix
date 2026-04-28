# frozen_string_literal: true

# SteeringCheck — Brute middleware that polls for queued user messages
# between iterations of the agentic tool loop.
#
# Inspired by PicoClaw's steering queue architecture (pkg/agent/steering.go).
# PicoClaw checks for steering messages after each tool execution; this
# middleware does the equivalent by running at the top of each ToolResultLoop
# iteration — after tools have executed and before the next LLM call.
#
# Place this between ToolResultLoop and MaxIterations in the middleware stack:
#
#   use Brute::Middleware::ToolResultLoop
#   use SteeringCheck, steering: steering_hash
#   use Brute::Middleware::MaxIterations
#   use Brute::Middleware::ToolCall
#   run Brute::Middleware::LLMCall.new
#
# The steering hash is a plain Hash { room_id => [String, ...] }. No mutex
# is needed because Falcon's cooperative fiber scheduler never preempts
# between in-memory operations — a fiber only yields at I/O boundaries.
#
# The room_id is resolved via Fiber[:room_id], which is set by the handler
# fiber before calling the agent. This is the natural scoping mechanism
# under Falcon — each request runs in its own fiber, so fiber-local storage
# is per-request without any sharing concerns.
#
# On each iteration:
#   1. Drains all queued messages for the current room
#   2. Injects each as a :user message into the session
#   3. Continues the inner pipeline (which will see the new messages)
#
# If no messages are queued, the middleware is a transparent pass-through.
#
class SteeringCheck
  MAX_QUEUE_SIZE = 10

  def initialize(app, steering:)
    @app = app
    @steering = steering
  end

  def call(env)
    room_id = Fiber[:room_id]

    if room_id && (queue = @steering[room_id]) && queue.any?
      # Drain all pending messages at once (PicoClaw's SteeringAll mode).
      # This is a single in-memory operation — no fiber can interleave here.
      # Messages pushed after this point (by another fiber yielding during
      # the LLM call below) will land in a fresh array and be picked up
      # on the next iteration.
      messages = queue.dup
      queue.clear

      messages.each do |content|
        env[:messages].user(content)
      end

      env[:events] << {
        type: :steering,
        data: { count: messages.size, room_id: room_id }
      }
    end

    @app.call(env)
  end

  # Push a message into the steering queue for a room.
  # Returns true on success, false if the queue is full.
  def self.enqueue(steering, room_id, content, max: MAX_QUEUE_SIZE)
    queue = (steering[room_id] ||= [])
    return false if queue.size >= max
    queue << content
    true
  end
end
