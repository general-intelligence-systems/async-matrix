# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/wrapper/json"

require_relative "../oauth/error"

module Async
  module Matrix
    module Wrapper
      # The wrapper for the authorization server's registration endpoint.
      #
      # Registering a client is the one request sent as JSON rather than a form.
      class ClientRegistration < ::Async::REST::Wrapper::JSON
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
      end
    end
  end
end
