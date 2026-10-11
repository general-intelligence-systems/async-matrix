# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/secret_send"

module Async
  module Matrix
    module Events
      class SecretSend < Content
        class << self
          def event_type = "m.secret.send"

          def framing = :event
        end

        def request_id = @value[:request_id]

        def secret = @value[:secret]
      end
    end
  end
end
