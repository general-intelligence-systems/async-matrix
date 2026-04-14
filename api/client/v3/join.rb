# frozen_string_literal: true

# POST /_matrix/client/v3/join/:roomIdOrAlias
# Auth: yes | Rate-limited: yes
# Response: 200, 400, 403, 429
module MatrixApi
  module Client
    module V3
      class Join < Base
        desc 'Join a room by ID or alias.' do
          detail 'Start the user participating in a particular room, by room ID or alias.'
          failure [
            [400, 'Bad request'],
            [403, 'Forbidden (e.g. invite-only room)'],
            [429, 'Rate limited (M_LIMIT_EXCEEDED)']
          ]
        end
        params do
          requires :roomIdOrAlias, type: String, desc: 'The room ID or alias'
          optional :server_name, type: Array[String], desc: 'Servers to attempt joining through'
          optional :reason, type: String, desc: 'Reason for joining'
          optional :third_party_signed, type: Hash, desc: 'Third-party signed invite token'
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
