# frozen_string_literal: true

# GET /_matrix/federation/v1/make_knock/:roomId/:userId
# Auth: yes | Rate-limited: no
# Response: 200, 400, 403, 404
module MatrixApi
  module Federation
    module V1
      class MakeKnock < Base
        desc 'Request a knock event template from the resident server.' do
          failure [
            [400, 'Incompatible room version'],
            [403, 'Not permitted to knock'],
            [404, 'Unknown room']
          ]
        end
        params do
          requires :ver, type: Array[String], desc: 'Room versions the knocking server supports'
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
