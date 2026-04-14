# frozen_string_literal: true

# POST /_matrix/app/v1/ping
# Auth: yes (hs_token) | Rate-limited: no | Added v1.7
# Response: 200
module MatrixApi
  module App
    module V1
      class Ping < Base
        desc 'Verify connectivity between homeserver and application service.' do
          detail 'Called by the HS to verify the hs_token and connection work.'
        end
        params do
          optional :transaction_id, type: String, desc: 'Transaction ID from the client ping call'
        end
        post do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
