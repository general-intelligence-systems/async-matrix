# frozen_string_literal: true

# POST /_matrix/client/v1/appservice/:appserviceId/ping
# Auth: yes (as_token) | Rate-limited: no | Added v1.7
# Response: 200, 400, 403, 502, 504
module MatrixApi
  module Client
    module V1
      class Appservice < Base
        route_param :appserviceId, type: String, desc: 'The appservice ID to ping' do
          desc 'Ping an application service via the homeserver.' do
            detail 'Asks the HS to call /_matrix/app/v1/ping on the AS to verify connectivity.'
            failure [
              [400, 'Appservice has no URL configured (M_URL_NOT_SET)'],
              [403, 'Token doesn\'t belong to this appservice (M_FORBIDDEN)'],
              [502, 'Appservice returned bad status or connection failed (M_BAD_STATUS, M_CONNECTION_FAILED)'],
              [504, 'Connection to appservice timed out (M_CONNECTION_TIMEOUT)']
            ]
          end
          params do
            optional :transaction_id, type: String, desc: 'Transaction ID passed through to the AS ping'
          end
          post :ping do
            authenticate!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
