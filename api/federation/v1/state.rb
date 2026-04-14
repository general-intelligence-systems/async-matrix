# frozen_string_literal: true

# GET /_matrix/federation/v1/state/:roomId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class State < Base
        desc 'Get the full state of a room at a given event.'
        params do
          requires :event_id, type: String, desc: 'The event ID to get state at'
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
