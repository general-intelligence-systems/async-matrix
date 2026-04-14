# frozen_string_literal: true

# PUT /_matrix/federation/v1/3pid/onbind
# Auth: no | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class ThirdPid < Base
        desc 'Notify a server that a 3PID has been bound to a Matrix user.' do
          detail 'Called by identity servers when a 3PID is bound.'
        end
        params do
          requires :address, type: String, desc: 'The 3pid (e.g. email address)'
          requires :medium, type: String, desc: 'Type of 3pid (e.g. email)'
          requires :mxid, type: String, desc: 'Bound Matrix user ID'
          requires :invites, type: Array, desc: 'Pending third-party invites'
        end
        put :onbind do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
