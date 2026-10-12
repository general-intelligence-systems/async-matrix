# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "generic"

module Async
  module Matrix
    module Identifier
      # The one identifier a room has, which is opaque to a client.
      #
      # Older room versions name the server which created it; later ones carry a hash instead.
      class RoomID < Generic
        SIGIL = "!"

        # Whether the room version wrote the server name into it.
        #
        # @returns [Boolean] whether it carries a server name.
        def namespaced?
          !@server_name.nil?
        end
      end
    end
  end
end
