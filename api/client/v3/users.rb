# frozen_string_literal: true

# POST /_matrix/client/v3/users/:userId/report
# Auth: yes | Rate-limited: yes | Added v1.18
# Response: 200, 404, 429
module MatrixApi
  module Client
    module V3
      class Users < Base
        route_param :userId, type: String, desc: 'The user ID' do
          # POST /users/:userId/report
          desc 'Report a user.' do
            failure [
              [404, 'User not found'],
              [429, 'Rate limited']
            ]
          end
          params do
            requires :reason, type: String, desc: 'Reason for the report'
            optional :room_id, type: String, desc: 'Room context'
          end
          post :report do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
