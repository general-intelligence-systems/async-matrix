# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/wrapper/json"

require_relative "error"
require_relative "payload"

module Async
  module Matrix
    # The JSON wrapper, corrected for two Matrix deviations.
    #
    # Errors are a non-2xx status with an `{errcode, error}` body, which this raises rather than returning.
    class Wrapper < Async::REST::Wrapper::JSON
      include Payload

      # The longest delay we will wait before retrying a rate limited request. A longer delay is reported to the caller as an error, rather than silently blocking the task.
      MAXIMUM_RETRY_DELAY = 30.0

      # How many times a request is sent before the rate limit is reported to the caller.
      #
      # {MAXIMUM_RETRY_DELAY} bounds one wait, not the total: a homeserver which answers 429 with `retry-after: 1` forever would spin here without it.
      MAXIMUM_ATTEMPTS = 3

      # Make the request, retrying if the server reports a rate limit.
      #
      # A retry needs a fresh request: the resource mutates the one it is given.
      #
      # @parameter resource [Async::REST::Resource] the resource to make the request against.
      # @parameter method [String] the HTTP method to use.
      # @parameter payload [Object | nil] the request payload, if any.
      # @yields {|response| ...} the response, once it is successful.
      def call(resource, method = "GET", payload = nil, &block)
        attempt = 1

        while true
          request = ::Protocol::HTTP::Request[method, nil]
          self.prepare_request(request, payload)

          response = resource.call(request)

          unless response.status == 429
            break
          end

          delay = self.retry_delay(response)

          # Reported to the caller rather than retried: the server asked us to wait longer than we are willing to, or it has had every attempt it is going to get.
          if delay.nil? or attempt >= MAXIMUM_ATTEMPTS
            break
          end

          response.close
          attempt += 1

          sleep(delay)
        end

        # If we exit this block because of an exception, close the response, so that we don't leave a dangling connection:
        begin
          self.process_response(request, response)

          yield response
        rescue
          response.close

          raise
        end
      end

      # @parameter request [Protocol::HTTP::Request] the request that was made.
      # @parameter response [Protocol::HTTP::Response] the response that was received.
      # @returns [Protocol::HTTP::Response] the response.
      # @raises [RequestError] if the response was not successful.
      def process_response(request, response)
        super

        unless response.success?
          errcode, message = self.error_for(response)

          raise RequestError.new(response.status, errcode, message)
        end

        response
      end

      # How long to wait before retrying a rate limited request.
      #
      # @parameter response [Protocol::HTTP::Response] the rate limited response.
      # @returns [Numeric | nil] the delay in seconds, or nil if the request should not be retried.
      private def retry_delay(response)
        # Reading the body both frees the connection for reuse and gives us `retry_after_ms`:
        payload = self.read_payload(response)

        if retry_after = response.headers["retry-after"]
          delay = self.retry_after_duration(retry_after)
        elsif retry_after_ms = payload&.fetch(:retry_after_ms, nil)
          delay = retry_after_ms / 1000.0
        end

        # Nothing said how long to wait, or it asked for longer than we are willing to: the caller is told about the rate limit instead.
        if delay and delay <= MAXIMUM_RETRY_DELAY
          delay
        end
      end

      # Extract the Matrix error code and message from an unsuccessful response.
      #
      # @parameter response [Protocol::HTTP::Response] the unsuccessful response.
      # @returns [Tuple(String | nil, String | nil)] the error code and message.
      private def error_for(response)
        payload = response.read

        if payload.is_a?(Hash)
          [payload[:errcode], payload[:error]]
        else
          [nil, payload&.to_s]
        end
      rescue => error
        # The body was not readable or was not valid JSON - the status is still meaningful:
        [nil, error.message]
      end
    end
  end
end
