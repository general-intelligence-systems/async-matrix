# frozen_string_literal: true

# GET /_matrix/app/v1/users/:userId
# Auth: yes (hs_token) | Rate-limited: no
# Response: 200, 401, 403, 404
module MatrixApi
  module App
    module V1
      class Users < Base
        desc 'Query existence of a user ID.' do
          detail 'HS queries if a user exists in the AS namespace. AS should create the user if desired.'
          failure [
            [401, 'Homeserver has not supplied credentials'],
            [403, 'Credentials rejected'],
            [404, 'User does not exist']
          ]
        end
        get ':userId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
