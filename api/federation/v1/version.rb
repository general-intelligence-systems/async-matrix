# frozen_string_literal: true

# GET /_matrix/federation/v1/version
# Auth: no | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class Version < Base
        desc 'Get the implementation name and version of this homeserver.'
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
