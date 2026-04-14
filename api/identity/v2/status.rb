# frozen_string_literal: true

# GET /_matrix/identity/v2
# Auth: no | Rate-limited: no
# Response: 200
module MatrixApi
  module Identity
    module V2
      class Status < Base
        desc 'Check that the identity server is available.' do
          detail 'Returns empty object. Used for auto-discovery and health checks.'
        end
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
