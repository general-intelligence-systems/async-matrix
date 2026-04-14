# frozen_string_literal: true

# GET /_matrix/client/v3/capabilities
# Auth: yes | Rate-limited: yes
# Response: 200, 429
module MatrixApi
  module Client
    module V3
      class Capabilities < Base
        desc 'Get information about the server capabilities.' do
          detail 'Gets capabilities that the server supports: password changes, room versions, etc.'
          failure [[429, 'Rate limited (M_LIMIT_EXCEEDED)']]
        end
        get do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
