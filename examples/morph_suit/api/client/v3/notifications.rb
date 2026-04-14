# frozen_string_literal: true

# GET /_matrix/client/v3/notifications
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Client
    module V3
      class Notifications < Base
        desc 'Get a list of events that the user has been notified about.'
        params do
          optional :from, type: String, desc: 'Pagination token'
          optional :limit, type: Integer, desc: 'Maximum number of events to return'
          optional :only, type: String, desc: 'Allows basic filtering of events'
        end
        get do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
