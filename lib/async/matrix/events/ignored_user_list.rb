# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/ignored_user_list"

module Async
  module Matrix
    module Events
      class IgnoredUserList < Content
        class << self
          def event_type = "m.ignored_user_list"

          def framing = :event
        end

        def ignored_users = @value[:ignored_users]
      end
    end
  end
end
