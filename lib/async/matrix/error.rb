# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    # The base class for all errors raised by this library.
    class Error < StandardError
    end

    # Represents a Matrix API error, which is reported with a non-2xx status and a body of the form
    # `{"errcode": "M_FORBIDDEN", "error": "..."}`.
    class RequestError < Error
      # @parameter status [Integer] the HTTP status code of the response.
      # @parameter errcode [String | nil] the Matrix error code, e.g. `M_FORBIDDEN`.
      # @parameter message [String | nil] the human readable error message.
      def initialize(status, errcode, message = nil)
        super(message || errcode || "HTTP #{status}")

        @status = status
        @errcode = errcode
      end

      # @attribute [Integer] the HTTP status code of the response.
      attr :status

      # @attribute [String | nil] the Matrix error code, e.g. `M_FORBIDDEN`.
      attr :errcode

      # @returns [Boolean] whether the access token was missing, invalid or expired.
      def unknown_token?
        @errcode == "M_UNKNOWN_TOKEN" or @errcode == "M_MISSING_TOKEN"
      end

      # @returns [Boolean] whether the request was rate limited.
      def limit_exceeded?
        @errcode == "M_LIMIT_EXCEEDED"
      end

      def to_s
        "#{@errcode || @status}: #{super}"
      end
    end
  end
end
