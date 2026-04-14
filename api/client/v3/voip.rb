# frozen_string_literal: true

# GET /_matrix/client/v3/voip/turnServer
# Auth: yes | Rate-limited: yes
# Response: 200, 429
module MatrixApi
  module Client
    module V3
      class Voip < Base
        desc 'Get TURN server credentials.' do
          failure [[429, 'Rate limited']]
        end
        get :turnServer do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
