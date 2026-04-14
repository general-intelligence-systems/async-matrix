# frozen_string_literal: true

# /_matrix/client/v3/events (deprecated)
module MatrixApi
  module Client
    module V3
      class Events < Base
        # GET /events (deprecated) - long-poll
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Listen for events (deprecated).'
        params do
          optional :from, type: String, desc: 'Pagination token'
          optional :timeout, type: Integer, desc: 'Max wait time (ms)'
        end
        get do
          authenticate!
          # TODO: implement - deprecated
          status 200
        end

        # GET /events/:eventId (deprecated)
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Get a single event by ID (deprecated).'
        get ':eventId' do
          authenticate!
          # TODO: implement - deprecated
          status 200
        end
      end
    end
  end
end
