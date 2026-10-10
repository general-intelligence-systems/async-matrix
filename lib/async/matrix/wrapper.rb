# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/wrapper/json"

require "protocol/http/body/buffered"

require_relative "error"

module Async
  module Matrix
    # Matrix speaks JSON in both directions, so most of the work is done by the standard JSON
    # wrapper. It deviates from `Async::REST`'s defaults in two ways, which this wrapper corrects:
    #
    # - Errors are reported with a non-2xx status and a `{errcode, error}` body. The generated
    #   class methods (e.g. `Representation.get`) do not check the response status, so a failed
    #   request would otherwise produce a representation wrapping an error body. We raise instead.
    #
    # - Rate limiting is reported as `M_LIMIT_EXCEEDED` with `retry_after_ms` in the response
    #   *body*, where `Async::REST::Wrapper::Generic` only understands the `retry-after` *header*.
    #   Newer homeservers send both, so we prefer the header and fall back to the body.
    class Wrapper < Async::REST::Wrapper::JSON
      # The longest delay we will wait before retrying a rate limited request. A longer delay is
      # reported to the caller as an error, rather than silently blocking the task.
      MAXIMUM_RETRY_DELAY = 30.0

      # Make the request, retrying if the server reports that we have been rate limited.
      #
      # This replaces {Async::REST::Wrapper::Generic#call} rather than overriding `response_for`,
      # because a retry needs a *fresh* request: the resource merges its own headers and path into
      # the request it is given, so re-dispatching the same request object applies them twice, and
      # a duplicated `authorization` header is rejected by the server. Rebuilding the request also
      # re-encodes the payload, so the body does not need to be replayable.
      #
      # @parameter resource [Async::REST::Resource] the resource to make the request against.
      # @parameter method [String] the HTTP method to use.
      # @parameter payload [Object | nil] the request payload, if any.
      # @yields {|response| ...} the response, once it is successful.
      def call(resource, method = "GET", payload = nil, &block)
        while true
          request = ::Protocol::HTTP::Request[method, nil]
          self.prepare_request(request, payload)

          response = resource.call(request)

          break unless response.status == 429

          delay = self.retry_delay(response)

          # The server asked us to wait longer than we are willing to: report it to the caller.
          break if delay.nil?

          response.close

          sleep(delay)
        end

        # If we exit this block because of an exception, close the response, so that we don't leave
        # a dangling connection:
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

        return response
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
        else
          return nil
        end

        return delay if delay <= MAXIMUM_RETRY_DELAY
      end

      # Extract the Matrix error code and message from an unsuccessful response.
      #
      # @parameter response [Protocol::HTTP::Response] the unsuccessful response.
      # @returns [Tuple(String | nil, String | nil)] the error code and message.
      private def error_for(response)
        payload = response.read

        if payload.is_a?(Hash)
          return payload[:errcode], payload[:error]
        else
          return nil, payload&.to_s
        end
      rescue => error
        # The body was not readable or was not valid JSON - the status is still meaningful:
        return nil, error.message
      end

      # Read a JSON payload from the response, leaving the response readable by the caller.
      #
      # @parameter response [Protocol::HTTP::Response] the response to read.
      # @returns [Hash | nil] the parsed payload, if it was valid JSON.
      private def read_payload(response)
        return nil unless body = response.body
        return nil unless buffer = body.join

        # `join` consumes the body, so replace it with an equivalent buffered body:
        response.body = ::Protocol::HTTP::Body::Buffered.new([buffer])

        return ::JSON.parse(buffer, symbolize_names: true)
      rescue ::JSON::ParserError
        return nil
      end
    end
  end
end
