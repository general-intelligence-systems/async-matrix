# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "json"

module Async
  module Matrix
    module Wrapper
      # Reads a body as a document whatever the server declares it to be.
      #
      # A push gateway sends one without saying so: sygnal writes `json.dumps` and leaves twisted's default.
      class Lenient < JSON
        # The parser for a response, which is the JSON parser whatever the response says.
        #
        # @parameter response [Protocol::HTTP::Response] the response to read.
        # @returns [Class] the parser.
        def parser_for(response)
          Parser
        end
      end
    end
  end
end
