# frozen_string_literal: true

# GET /_matrix/federation/v1/backfill/:roomId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class Backfill < Base
        desc 'Retrieve a sliding window of previous PDUs for a room.'
        params do
          requires :v, type: Array[String], desc: 'Event IDs to backfill from'
          requires :limit, type: Integer, desc: 'Maximum number of PDUs to return'
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
