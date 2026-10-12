# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "error"

module Async
  module Matrix
    # Raised when a string is not the identifier it was read as.
    class InvalidIdentifierError < Error
    end

    # The identifiers the appendices give a grammar.
    module Identifier
    end
  end
end

require_relative "identifier/event_id"
require_relative "identifier/generic"
require_relative "identifier/namespaced"
require_relative "identifier/opaque"
require_relative "identifier/room_alias"
require_relative "identifier/room_id"
require_relative "identifier/server_name"
require_relative "identifier/user_id"
