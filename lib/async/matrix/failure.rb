# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "json"

require "async/rest/wrapper/json"

require "protocol/http/body/rewindable"

module Async
  module Matrix
    # The error a homeserver reported.
    #
    # Every error has the same shape, so one reader serves both middlewares.
    class Failure
      # The parser the body is read with, which is the one the wrapper would have attached.
      PARSER = ::Async::REST::Wrapper::JSON::Parser

      # The error codes which say the access token itself is the problem.
      UNKNOWN_TOKEN = ["M_UNKNOWN_TOKEN", "M_MISSING_TOKEN"].freeze

      # The error the response reports, leaving the response readable by the caller.
      #
      # @parameter response [Protocol::HTTP::Response] the response to read.
      # @returns [Failure | nil] the error, if the body was a JSON object.
      def self.for(response)
        body = response.body
        rewindable = nil

        if body
          rewindable = ::Protocol::HTTP::Body::Rewindable.new(body)
          response.body = rewindable

          payload = PARSER.new(rewindable).join
          rewindable.rewind

          if payload.is_a?(Hash)
            self.new(payload)
          end
        end
      rescue ::JSON::ParserError
        rewindable&.rewind

        nil
      end

      # @parameter payload [Hash] the error body.
      def initialize(payload)
        @payload = payload
      end

      # @returns [String | nil] the Matrix error code, e.g. `M_FORBIDDEN`.
      def errcode
        @payload[:errcode]
      end

      # @returns [String | nil] the human readable error message.
      def message
        @payload[:error]
      end

      # @returns [Integer | nil] how long to wait before trying again, in milliseconds.
      def retry_after_ms
        @payload[:retry_after_ms]
      end

      # @returns [Boolean] whether the access token was missing, invalid or expired.
      def unknown_token?
        UNKNOWN_TOKEN.include?(@payload[:errcode])
      end

      def inspect
        "\#<#{self.class} #{self.errcode}>"
      end
    end
  end
end
