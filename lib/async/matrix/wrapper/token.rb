# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/wrapper/form"

require_relative "../oauth/error"

module Async
  module Matrix
    module Wrapper
      # The wrapper for the authorization server's token endpoint.
      #
      # A token request is form encoded and answered with JSON, which is what the endpoint asks for.
      class Token < ::Async::REST::Wrapper::Form
        # Report what the authorization server refused.
        #
        # @parameter request [Protocol::HTTP::Request] the request that was made.
        # @parameter response [Protocol::HTTP::Response] the response that was received.
        # @returns [Protocol::HTTP::Response] the response.
        # @raises [OAuth::Error] if the authorization server refused.
        def process_response(request, response)
          super

          unless response.success?
            error, description = OAuth.error_for(response)

            raise OAuth::Error.new(response.status, error, description)
          end

          response
        end

        # Which parser to use, if the response says what it is.
        #
        # A response with no content type is left alone rather than raising.
        #
        # @parameter response [Protocol::HTTP::Response] the response to parse.
        # @returns [Class | nil] the parser.
        def parser_for(response)
          if response.headers["content-type"]
            super
          end
        end
      end
    end
  end
end
