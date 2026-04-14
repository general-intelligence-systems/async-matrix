# frozen_string_literal: true

# GET /_matrix/federation/v1/hierarchy/:roomId
# Auth: yes | Rate-limited: no
# Response: 200, 404
module MatrixApi
  module Federation
    module V1
      class Hierarchy < Base
        desc 'Get the space hierarchy for a room (federation).' do
          failure [[404, 'Room unknown or inaccessible']]
        end
        params do
          optional :suggested_only, type: Boolean, desc: 'Only return suggested rooms'
        end
        get ':roomId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
