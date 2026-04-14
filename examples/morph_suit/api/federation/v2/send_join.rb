# frozen_string_literal: true

# PUT /_matrix/federation/v2/send_join/:roomId/:eventId
# Auth: yes | Rate-limited: no
# Response: 200, 400, 403
module MatrixApi
  module Federation
    module V2
      class SendJoin < Base
        desc 'Submit a signed join event to the resident server.' do
          failure [
            [400, 'Invalid request / unable to authorise join'],
            [403, 'User not permitted to join']
          ]
        end
        params do
          optional :omit_members, type: Boolean, desc: 'Omit m.room.member events from response (added v1.6)'
          # Body is a signed membership event PDU
        end
        put ':roomId/:eventId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
