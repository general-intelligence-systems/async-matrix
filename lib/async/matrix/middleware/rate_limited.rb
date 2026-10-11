# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/http/middleware"

require_relative "repeatable"
require_relative "../failure"

module Async
  module Matrix
    module Middleware
      # Waits out a rate limit and sends the request again.
      #
      # It sits below the resource, so a request can be sent again without its path and headers being applied twice.
      class RateLimited < ::Protocol::HTTP::Middleware
        include Repeatable

        # The status a homeserver reports a rate limit with.
        TOO_MANY_REQUESTS = 429

        # The longest delay we will wait before sending the request again. A longer delay is reported to the caller, rather than silently blocking the task.
        MAXIMUM_RETRY_DELAY = 30.0

        # How many times a request is sent before the rate limit is reported to the caller.
        #
        # {MAXIMUM_RETRY_DELAY} bounds one wait, not the total: a homeserver which answers 429 with `retry-after: 1` forever would spin here without it.
        MAXIMUM_ATTEMPTS = 3

        # Make the request, waiting and sending it again while the homeserver reports a rate limit.
        #
        # @parameter request [Protocol::HTTP::Request] the request to make.
        # @returns [Protocol::HTTP::Response] the response.
        def call(request)
          attempt = 1

          while true
            response = @delegate.call(request)

            unless response.status == TOO_MANY_REQUESTS and self.repeatable?(request)
              break response
            end

            delay = self.retry_delay(response)

            # Reported to the caller rather than retried: the homeserver asked us to wait longer than we are willing to, or it has had every attempt it is going to get.
            if delay.nil? or attempt >= MAXIMUM_ATTEMPTS
              break response
            end

            response.close
            attempt += 1

            sleep(delay)

            self.rewind(request)
          end
        end

        # How long to wait before sending a rate limited request again.
        #
        # @parameter response [Protocol::HTTP::Response] the rate limited response.
        # @returns [Numeric | nil] the delay in seconds, or nil if it should not be sent again.
        private def retry_delay(response)
          delay = nil

          if retry_after = response.headers["retry-after"]
            delay = self.retry_after_duration(retry_after)
          elsif retry_after_ms = Failure.for(response)&.retry_after_ms
            delay = retry_after_ms / 1000.0
          end

          # Nothing said how long to wait, or it asked for longer than we are willing to: the caller is told about the rate limit instead.
          if delay and delay <= MAXIMUM_RETRY_DELAY
            delay
          end
        end

        # How long a `retry-after` header asks us to wait, which is either a date or a number of seconds.
        #
        # @parameter value [String] the header value.
        # @returns [Numeric] the delay in seconds.
        private def retry_after_duration(value)
          [Time.httpdate(value) - Time.now, 0].max
        rescue ArgumentError
          value.to_f
        end
      end
    end
  end
end
