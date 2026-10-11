# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Middleware
      # Sends a request more than once.
      module Repeatable
        # Whether the request can be sent again, which a body it cannot replay prevents.
        #
        # @parameter request [Protocol::HTTP::Request] the request to examine.
        # @returns [Boolean] whether it can be sent again.
        private def repeatable?(request)
          request.body.nil? or request.body.rewindable?
        end

        # Wind the body back, so that the request can be sent again.
        #
        # @parameter request [Protocol::HTTP::Request] the request to rewind.
        # @returns [Nil] nothing.
        private def rewind(request)
          request.body&.rewind

          nil
        end
      end
    end
  end
end
