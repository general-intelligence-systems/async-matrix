# frozen_string_literal: true

# PUT /_matrix/federation/v1/send_knock/:roomId/:eventId
# Auth: yes | Rate-limited: no
# Response: 200, 400, 403, 404
module MatrixApi
  module Federation
    module V1
      class SendKnock < Base
        desc 'Submit a signed knock event to the resident server.' do
          failure [
            [400, 'Invalid request'],
            [403, 'Not permitted to knock'],
            [404, 'Unknown room']
          ]
        end
        put ':roomId/:eventId' do
          authenticate!
          # TODO: implement - body is signed membership PDU
          status 200
        end
      end
    end
  end
end
