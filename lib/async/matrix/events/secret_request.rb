# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/secret_request"

module Async
  module Matrix
    module Events
      class SecretRequest < Content
        class << self
          def event_type = "m.secret.request"

          def framing = :event
        end

        def name = @value[:name]

        def action = @value[:action]

        def requesting_device_id = @value[:requesting_device_id]

        def request_id = @value[:request_id]
      end
    end
  end
end
