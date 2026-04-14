# frozen_string_literal: true

# POST /_matrix/federation/v1/get_missing_events/:roomId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class GetMissingEvents < Base
        desc 'Retrieve events that the sender is missing.'
        params do
          requires :earliest_events, type: Array[String], desc: 'Latest events already known'
          requires :latest_events, type: Array[String], desc: 'Events to work backwards from'
          optional :limit, type: Integer, default: 10, desc: 'Max events to return'
          optional :min_depth, type: Integer, default: 0, desc: 'Minimum depth of events'
        end
        post ':roomId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
