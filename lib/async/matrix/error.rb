# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    # The base class for all errors raised by this library.
    class Error < StandardError
    end

    # Represents a Matrix API error, which is reported with a non-2xx status and a body of the form `{"errcode": "M_FORBIDDEN", "error": "..."}`.
    class RequestError < Error
      # @parameter status [Integer] the HTTP status code of the response.
      # @parameter errcode [String | nil] the Matrix error code, e.g. `M_FORBIDDEN`.
      # @parameter message [String | nil] the human readable error message.
      def initialize(status, errcode, message = nil)
        super(message || errcode || "HTTP #{status}")

        @status = status
        @errcode = errcode
      end

      # @attribute [Integer] the HTTP status code of the response.
      attr :status

      # @attribute [String | nil] the Matrix error code, e.g. `M_FORBIDDEN`.
      attr :errcode

      # @returns [Boolean] whether the access token was missing, invalid or expired.
      def unknown_token?
        @errcode == "M_UNKNOWN_TOKEN" or @errcode == "M_MISSING_TOKEN"
      end

      # @returns [Boolean] whether the request was rate limited.
      def limit_exceeded?
        @errcode == "M_LIMIT_EXCEEDED"
      end

      def to_s
        "#{@errcode || @status}: #{super}"
      end
    end

    # Raised when the homeserver wants the user to authenticate again before it will act.
    #
    # The challenge names the flows it accepts and the session to carry through them.
    class InteractiveAuthenticationError < RequestError
      # @parameter status [Integer] the HTTP status code of the response.
      # @parameter errcode [String | nil] the Matrix error code, if the stage failed.
      # @parameter message [String | nil] the human readable error message.
      # @parameter session [String | nil] the session to send with each stage.
      # @parameter flows [Array(Hash) | nil] the flows the homeserver accepts.
      # @parameter params [Hash | nil] the parameters a stage needs, by stage type.
      # @parameter completed [Array(String) | nil] the stages already completed.
      def initialize(status, errcode, message = nil, session: nil, flows: nil, params: nil, completed: nil)
        super(status, errcode, message || "The homeserver requires authentication.")

        @session = session
        @flows = flows || []
        @params = params || {}
        @completed = completed || []
      end

      # @attribute [String | nil] the session to send with each stage.
      attr :session

      # @attribute [Array(Hash)] the flows the homeserver accepts.
      attr :flows

      # @attribute [Hash] the parameters a stage needs, by stage type.
      attr :params

      # @attribute [Array(String)] the stages already completed.
      attr :completed

      # @returns [Array(Array(String))] the stages of each flow it accepts.
      def stages
        @flows.map{|flow| Array(flow[:stages])}
      end

      # Whether a flow exists whose remaining stages are only of the given type.
      #
      # @parameter type [String] the stage type, e.g. `m.login.password`.
      # @returns [Boolean] whether that single stage would complete a flow.
      def accepts?(type)
        self.stages.any?{|stages| stages - @completed == [type]}
      end
    end

    # Raised when a rejected access token could not be replaced, so the caller must log in again.
    #
    # It is a {RequestError}: the refusal is the `cause`.
    class AuthenticationError < RequestError
    end
  end
end
