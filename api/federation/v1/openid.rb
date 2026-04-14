# frozen_string_literal: true

# GET /_matrix/federation/v1/openid/userinfo
# Auth: no | Rate-limited: no
# Response: 200, 401
module MatrixApi
  module Federation
    module V1
      class Openid < Base
        desc 'Verify an OpenID token and return the user ID.' do
          failure [[401, 'Token not recognized or expired']]
        end
        params do
          requires :access_token, type: String, desc: 'The OpenID access token to verify'
        end
        get :userinfo do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
