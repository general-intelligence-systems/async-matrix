# frozen_string_literal: true

# GET /_matrix/federation/v1/timestamp_to_event/:roomId
# Auth: yes | Rate-limited: no
# Response: 200, 404
module MatrixApi
  module Federation
    module V1
      class TimestampToEvent < Base
        desc 'Get the closest event to a given timestamp.' do
          failure [[404, 'No event found']]
        end
        params do
          requires :ts, type: Integer, desc: 'Milliseconds since Unix epoch'
          requires :dir, type: String, values: %w[f b], desc: 'Direction to search'
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
