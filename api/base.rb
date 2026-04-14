# frozen_string_literal: true

module MatrixApi
  # Base API class providing shared configuration for all Matrix Client-Server API endpoints.
  # All mounted API classes inherit format, error handling, and authentication helpers from here.
  #
  # Matrix Client-Server API v1.18
  # https://spec.matrix.org/v1.18/client-server-api/
  class Base < Grape::API
    format :json
    content_type :json, 'application/json'

    # ---------------------------------------------------------------------------
    # Helpers available to every endpoint
    # ---------------------------------------------------------------------------
    helpers do
      # Authenticate the request via Bearer token.
      # Raises M_MISSING_TOKEN (401) or M_UNKNOWN_TOKEN (401).
      def authenticate!
        # TODO: implement token lookup
        error!({ errcode: 'M_MISSING_TOKEN', error: 'No access token supplied.' }, 401) unless access_token
        error!({ errcode: 'M_UNKNOWN_TOKEN', error: 'Unrecognised access token.' }, 401) unless current_user
      end

      def access_token
        # Bearer token from header or query param
        @access_token ||= (headers['Authorization']&.sub(/\ABearer /, '') || params[:access_token])
      end

      def current_user
        # TODO: look up user from access_token
        nil
      end

      # Standard Matrix error response helper
      def matrix_error!(errcode, message, status = 400)
        error!({ errcode: errcode, error: message }, status)
      end

      # Rate-limit guard (placeholder)
      def rate_limit!
        # TODO: implement rate limiting; return M_LIMIT_EXCEEDED / 429
      end
    end

    # ---------------------------------------------------------------------------
    # Common error handling
    # ---------------------------------------------------------------------------
    rescue_from Grape::Exceptions::ValidationErrors do |e|
      error!({ errcode: 'M_BAD_JSON', error: e.message }, 400)
    end

    rescue_from :all do |e|
      error!({ errcode: 'M_UNKNOWN', error: e.message }, 500)
    end
  end
end
