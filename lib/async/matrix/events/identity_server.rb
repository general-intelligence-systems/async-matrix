# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

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
