# frozen_string_literal: true

# GET /_matrix/client/v3/joined_rooms
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Client
    module V3
      class JoinedRooms < Base
        desc 'Get a list of rooms the user has joined.' do
          detail 'Returns the list of rooms that the user has joined.'
        end
        get do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
