# frozen_string_literal: true

# GET /_matrix/app/v1/rooms/:roomAlias
# Auth: yes (hs_token) | Rate-limited: no
# Response: 200, 401, 403, 404
module MatrixApi
  module App
    module V1
      class Rooms < Base
        desc 'Query existence of a room alias.' do
          detail 'HS queries if a room alias exists in the AS namespace. AS should create the room if desired.'
          failure [
            [401, 'Homeserver has not supplied credentials'],
            [403, 'Credentials rejected'],
            [404, 'Room alias does not exist']
          ]
        end
        get ':roomAlias' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
