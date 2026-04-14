# frozen_string_literal: true

# GET /_matrix/federation/v1/event/:eventId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class Event < Base
        desc 'Retrieve a single event.'
        get ':eventId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
