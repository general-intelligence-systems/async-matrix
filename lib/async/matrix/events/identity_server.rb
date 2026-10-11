# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/identity_server"

module Async
  module Matrix
    module Events
      class IdentityServer < Content
        class << self
          def event_type = "m.identity_server"

          def framing = :event
        end

        def base_url = @value[:base_url]
      end
    end
  end
end
