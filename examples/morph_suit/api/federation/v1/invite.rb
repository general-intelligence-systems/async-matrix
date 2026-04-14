# frozen_string_literal: true

# PUT /_matrix/federation/v1/invite/:roomId/:eventId
# Auth: yes | Rate-limited: no
# Response: 200, 400, 403
module MatrixApi
  module Federation
    module V1
      class Invite < Base
        desc 'Invite a remote user to a room (v1 format).' do
          detail 'Body is the invite event itself. Response wraps in [200, {event}].'
          failure [
            [400, 'Invalid request'],
            [403, 'Invite not allowed (M_FORBIDDEN, M_INVITE_BLOCKED)']
          ]
        end
        put ':roomId/:eventId' do
          authenticate!
          # TODO: implement - body is invite event PDU
          status 200
        end
      end
    end
  end
end
