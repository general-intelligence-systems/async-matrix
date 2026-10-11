# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/http/middleware"

require_relative "credentials"
require_relative "payload"

module Async
  module Matrix
    # Authenticates every request, and replaces a rejected access token.
    #
    # It sits below the resource, so a request can be sent again without its path and headers being applied twice.
    class Authenticated < ::Protocol::HTTP::Middleware
      include Payload

      # The status a homeserver rejects an access token with.
      UNAUTHORIZED = 401

      # The error codes which say the access token itself is the problem. A 401 carrying anything else - the authentication flows a protected endpoint wants, say - is the caller's business, not ours.
      UNKNOWN_TOKEN = ["M_UNKNOWN_TOKEN", "M_MISSING_TOKEN"].freeze

      # @parameter delegate [Protocol::HTTP::Middleware] what handles requests.
      # @parameter credentials [Credentials] the access token to authenticate with.
      def initialize(delegate, credentials)
        super(delegate)

        @credentials = credentials
      end

      # @attribute [Credentials] the access token every request is authenticated with.
      attr :credentials

      # Authenticate the request, and try again with a new access token if it was rejected.
      #
      # @parameter request [Protocol::HTTP::Request] the request to make.
      # @returns [Protocol::HTTP::Response] the response.
      def call(request)
        generation = self.authorize(request)

        response = super

        if self.rejected?(response)
          self.retried(request, response, generation)
        else
          response
        end
      end

      def inspect
        "\#<#{self.class} #{@credentials.inspect}>"
      end

      # Set the authorization header, replacing whatever the resource supplied.
      #
      # `Protocol::HTTP::Headers#[]=` replaces where `merge` adds, and a homeserver rejects a request carrying two authorization headers.
      #
      # @parameter request [Protocol::HTTP::Request] the request to authenticate.
      # @returns [Integer] the generation of the token it now carries.
      private def authorize(request)
        authorization, generation = @credentials.authorization

        request.headers["authorization"] = authorization

        generation
      end

      # Whether the access token was rejected and there is something to replace it with.
      #
      # @parameter response [Protocol::HTTP::Response] the response to examine.
      # @returns [Boolean] whether to try again.
      private def rejected?(response)
        if response.status == UNAUTHORIZED and @credentials.renewable?
          self.unknown_token?(response)
        else
          false
        end
      end

      # Whether the homeserver said the access token was unknown, which it reports in the body.
      #
      # @parameter response [Protocol::HTTP::Response] the response to examine.
      # @returns [Boolean] whether the access token was the problem.
      private def unknown_token?(response)
        payload = self.read_payload(response)

        if payload
          UNKNOWN_TOKEN.include?(payload[:errcode])
        else
          false
        end
      end

      # Replace the access token and make the request again.
      #
      # @parameter request [Protocol::HTTP::Request] the request to make again.
      # @parameter response [Protocol::HTTP::Response] the rejected response.
      # @parameter generation [Integer] the generation of the rejected token.
      # @returns [Protocol::HTTP::Response] the second response, or the first if it cannot be repeated.
      private def retried(request, response, generation)
        if self.repeatable?(request)
          # Release the connection before asking for it again:
          response.close

          @credentials.renew!(generation)

          self.authorize(request)
          request.body&.rewind

          @delegate.call(request)
        else
          response
        end
      end

      # Whether the request can be made a second time, which a body it cannot replay prevents.
      #
      # @parameter request [Protocol::HTTP::Request] the request to examine.
      # @returns [Boolean] whether it can be made again.
      private def repeatable?(request)
        request.body.nil? or request.body.rewindable?
      end
    end
  end
end
