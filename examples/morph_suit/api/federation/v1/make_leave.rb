# frozen_string_literal: true

# GET /_matrix/federation/v1/make_leave/:roomId/:userId
# Auth: yes | Rate-limited: no
# Response: 200, 403
module MatrixApi
  module Federation
    module V1
      class MakeLeave < Base
        desc 'Request a leave event template from the resident server.' do
          failure [[403, 'Not authorized (user not in room)']]
        end
        get ':roomId/:userId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
