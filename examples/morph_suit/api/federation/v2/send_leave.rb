# frozen_string_literal: true

# PUT /_matrix/federation/v2/send_leave/:roomId/:eventId
# Auth: yes | Rate-limited: no
# Response: 200, 400
module MatrixApi
  module Federation
    module V2
      class SendLeave < Base
        desc 'Submit a signed leave event to the resident server.' do
          failure [[400, 'Invalid request']]
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
