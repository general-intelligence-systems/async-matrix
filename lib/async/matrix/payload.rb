# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "json"

require "protocol/http/body/buffered"

module Async
  module Matrix
    # Reads a JSON body without consuming it.
    module Payload
      # Read a JSON payload from the response, leaving the response readable by the caller.
      #
      # @parameter response [Protocol::HTTP::Response] the response to read.
      # @returns [Hash | nil] the parsed payload, if it was valid JSON.
      private def read_payload(response)
        if body = response.body
          if buffer = body.join
            # `join` consumes the body, so replace it with an equivalent buffered body:
            response.body = ::Protocol::HTTP::Body::Buffered.new([buffer])

            ::JSON.parse(buffer, symbolize_names: true)
          end
        end
      rescue ::JSON::ParserError
        nil
      end
    end
  end
end
