# frozen_string_literal: true

# GET /_matrix/key/v2/server
# Auth: no | Rate-limited: no
# Response: 200
module MatrixApi
  module Key
    module V2
      class Server < Base
        desc 'Get the homeserver\'s published signing keys.' do
          detail 'Returns active verify_keys, old_verify_keys, and signatures.'
        end
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
