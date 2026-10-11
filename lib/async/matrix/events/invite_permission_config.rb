# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
