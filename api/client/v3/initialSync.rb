# frozen_string_literal: true

# GET /_matrix/client/v3/initialSync (deprecated)
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Client
    module V3
      class InitialSync < Base
        desc 'Get the user initial sync data (deprecated).'
        params do
          optional :limit, type: Integer, desc: 'Max events to return'
        end
        get do
          authenticate!
          # TODO: implement - deprecated
          status 200
        end
      end
    end
  end
end
