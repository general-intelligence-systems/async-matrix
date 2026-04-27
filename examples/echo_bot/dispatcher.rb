# frozen_string_literal: true

module EchoBot
  # Routes incoming Matrix events to registered handler objects.
  #
  # Each handler declares the event types it handles via `#event_types`.
  # When an event arrives, the dispatcher finds all matching handlers
  # and calls them. Errors in one handler do not prevent others from running.
  class Dispatcher
    def initialize
      @handlers = Hash.new { |h, k| h[k] = [] }
    end

    def register(handler)
      handler.event_types.each do |type|
        @handlers[type] << handler
        Matrix.logger.info { "Registered #{handler.class.name} for #{type}" }
      end
    end

    def dispatch(event)
      type     = event.type
      handlers = @handlers[type]

      if handlers.empty?
        Matrix.logger.debug { "No handler for event type: #{type}" }
        return
      end

      handlers.each do |handler|
        handler.call(event)
      rescue => e
        Matrix.logger.error {
          "Handler #{handler.class.name} raised #{e.class}: #{e.message}"
        }
      end
    end

    def dispatch_transaction(body)
      txn = Matrix::ApplicationService::Models::Transaction.new(body)
      txn.events.each    { |event| dispatch(event) }
      txn.ephemeral.each { |event| dispatch(event) }
    end

    def handler_count
      @handlers.values.flatten.size
    end
  end
end
