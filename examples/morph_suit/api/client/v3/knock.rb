# frozen_string_literal: true

# POST /_matrix/client/v3/knock/:roomIdOrAlias
# Auth: yes | Rate-limited: yes | Added v1.1
# Response: 200, 400, 403, 404, 429
module MatrixApi
  module Client
    module V3
      class Knock < Base
        desc 'Knock on a room.' do
          detail 'Asks to be allowed to join the room. Room must allow knocking.'
          failure [
            [400, 'Bad request'],
            [403, 'Forbidden (knocking not allowed)'],
            [404, 'Room not found'],
            [429, 'Rate limited (M_LIMIT_EXCEEDED)']
          ]
        end
        params do
          requires :roomIdOrAlias, type: String, desc: 'The room ID or alias'
          optional :server_name, type: Array[String], desc: 'Servers to attempt through'
          optional :reason, type: String, desc: 'Reason for knocking'
        end
        post ':roomIdOrAlias' do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
