# frozen_string_literal: true

# GET /_matrix/client/v1/room_summary/:roomIdOrAlias
# Auth: optional | Rate-limited: yes | Added v1.18
# Response: 200, 400, 403, 404, 429
module MatrixApi
  module Client
    module V1
      class RoomSummary < Base
        desc 'Get a summary of a room.' do
          detail 'Get a summary of a room, without needing to join it.'
          failure [
            [400, 'Bad request'],
            [403, 'Forbidden'],
            [404, 'Room not found'],
            [429, 'Rate limited']
          ]
        end
        params do
          requires :roomIdOrAlias, type: String, desc: 'The room ID or alias'
          optional :via, type: Array[String], desc: 'Servers to attempt to fetch from'
        end
        get ':roomIdOrAlias' do
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
