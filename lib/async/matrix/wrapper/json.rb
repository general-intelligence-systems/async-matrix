# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

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
            raise self.error_for(response)
          end

          response
        end

        # The error an unsuccessful response reports.
        #
        # A body naming flows and a session is a challenge rather than a refusal.
        #
        # @parameter response [Protocol::HTTP::Response] the unsuccessful response.
        # @returns [RequestError] the error to raise.
        private def error_for(response)
          payload = response.read

          if payload.is_a?(Hash)
            if payload[:flows] and payload[:session]
              InteractiveAuthenticationError.new(response.status, payload[:errcode], payload[:error],
                session: payload[:session],
                flows: payload[:flows],
                params: payload[:params],
                completed: payload[:completed],
              )
            else
              RequestError.new(response.status, payload[:errcode], payload[:error])
            end
          else
            RequestError.new(response.status, nil, payload&.to_s)
          end
        rescue => error
          # The body was not readable or was not valid JSON - the status is still meaningful:
          RequestError.new(response.status, nil, error.message)
        end
      end
    end
  end
end
