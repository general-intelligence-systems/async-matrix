# frozen_string_literal: true

# GET /_matrix/federation/v1/state_ids/:roomId
# Auth: yes | Rate-limited: no
# Response: 200, 403, 404
module MatrixApi
  module Federation
    module V1
      class StateIds < Base
        desc 'Get the event IDs of the full state of a room at a given event.' do
          failure [
            [403, 'Forbidden (not in room / ACL\'d)'],
            [404, 'Event not found']
          ]
        end
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
