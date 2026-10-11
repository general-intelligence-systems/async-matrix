# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/invite_permission_config"

module Async
  module Matrix
    module Events
      class InvitePermissionConfig < Content
        class << self
          def event_type = "m.invite_permission_config"

          def framing = :event
        end
      end
    end
  end
end
