# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/wrapper/json"

require_relative "../error"

module Async
  module Matrix
    module Wrapper
      # The JSON wrapper, corrected for the way Matrix reports an error.
      #
      # An error is a non-2xx status with an `{errcode, error}` body, which this raises rather than returning.
      class JSON < ::Async::REST::Wrapper::JSON
        # Make the request, once.
        #
        # @parameter resource [Async::REST::Resource] the resource to make the request against.
        # @parameter request [Protocol::HTTP::Request] the request to make.
        # @returns [Protocol::HTTP::Response] the response.
        def response_for(resource, request)
          # The retry inherited from `Async::REST::Wrapper::Generic` would send a request the resource has already mutated a second time, duplicating `accept` and concatenating `authorization`. Waiting out a rate limit belongs below the resource, which is where `Middleware::RateLimited` does it.
          resource.call(request)
        end

        # Wrap the body, then raise if the homeserver refused.
        #
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

        # The Matrix error code and message from an unsuccessful response.
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
end
