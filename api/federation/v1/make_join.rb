# frozen_string_literal: true

# GET /_matrix/federation/v1/make_join/:roomId/:userId
# Auth: yes | Rate-limited: no
# Response: 200, 400, 403, 404
module MatrixApi
  module Federation
    module V1
      class MakeJoin < Base
        desc 'Request a join event template from the resident server.' do
          failure [
            [400, 'Incompatible room version / unable to authorise join'],
            [403, 'User not permitted to join'],
            [404, 'Unknown room']
          ]
        end
        params do
          optional :ver, type: Array[String], desc: 'Room versions the joining server supports'
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
