# frozen_string_literal: true

# PUT /_matrix/federation/v2/invite/:roomId/:eventId
# Auth: yes | Rate-limited: no
# Response: 200, 400, 403
module MatrixApi
  module Federation
    module V2
      class Invite < Base
        desc 'Invite a remote user to a room (v2 format).' do
          failure [
            [400, 'Invalid request / incompatible room version'],
            [403, 'Invite not allowed (M_FORBIDDEN, M_INVITE_BLOCKED)']
          ]
        end
        params do
          # Body:
          # event: InviteEvent (required)
          # invite_room_state: [PDU] (optional, stripped state)
          # room_version: string (required)
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
