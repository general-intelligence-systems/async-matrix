# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "generic"

module Async
  module Matrix
    module Identifier
      # A name a room answers to, resolved by the homeserver which created it.
      #
      # The localpart is any UTF-8 but a colon and NUL.
      class RoomAlias < Generic
        SIGIL = "#"

        def validate
          super

          self.require_server_name
        end
      end
    end
  end
end
