# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../error"

module Async
  module Matrix
    module OAuth
      # The error the authorization server reported.
      #
      # @parameter response [Protocol::HTTP::Response] the refusal.
      # @returns [Tuple(String, String | nil)] the error code and its description.
      def self.error_for(response)
        payload = response.read

        if payload.is_a?(Hash)
          [payload[:error] || "invalid_request", payload[:error_description]]
        else
          ["invalid_request", payload&.to_s]
        end
      rescue => error
        ["invalid_request", error.message]
      end

      # Raised when the authorization server refuses a request.
      #
      # A {RequestError}, so a caller which handles one refusal handles both.
      class Error < Matrix::RequestError
        # @returns [Boolean] whether the grant was rejected, so the caller must authorize again.
        def invalid_grant?
          self.errcode == "invalid_grant"
        end
      end
    end
  end
end
