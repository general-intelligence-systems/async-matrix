# frozen_string_literal: true

# /_matrix/client/v3/refresh
# Auth: no (uses refresh_token) | Rate-limited: yes | Added v1.3
# Response: 200, 401, 429
module MatrixApi
  module Client
    module V3
      class Refresh < Base
        desc 'Refresh an access token.' do
          detail 'Exchanges a refresh token for a new access token.'
          failure [
            [401, 'Unauthorized (M_UNKNOWN_TOKEN)'],
            [429, 'Rate limited (M_LIMIT_EXCEEDED)']
          ]
        end
        params do
          requires :refresh_token, type: String, desc: 'The refresh token'
        end
        post do
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
