# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "generic"

module Async
  module Matrix
    module Identifier
      # The one identifier an event has, which is opaque to a client.
      #
      # The room version decides the format, and nothing here reads further into it.
      class EventID < Generic
        SIGIL = "$"

        # Whether the room version which made this one wrote the server into it.
        #
        # @returns [Boolean] whether it carries a server name.
        def namespaced?
          !@server_name.nil?
        end
      end
    end
  end
end
