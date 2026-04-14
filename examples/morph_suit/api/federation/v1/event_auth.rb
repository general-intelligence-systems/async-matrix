# frozen_string_literal: true

# GET /_matrix/federation/v1/event_auth/:roomId/:eventId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class EventAuth < Base
        desc 'Retrieve the auth chain for an event.'
        get ':roomId/:eventId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
