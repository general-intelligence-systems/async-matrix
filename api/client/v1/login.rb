# frozen_string_literal: true

# POST /_matrix/client/v1/login/get_token
# Auth: yes | Rate-limited: yes | UIA | Added v1.7
# Response: 200, 400, 401, 429
module MatrixApi
  module Client
    module V1
      class Login < Base
        desc 'Generate a short-lived login token.' do
          detail 'Generates a token for use with m.login.token login. Requires UIA.'
          failure [
            [400, 'Bad request'],
            [401, 'Unauthorized / UIA required'],
            [429, 'Rate limited']
          ]
        end
        params do
          optional :auth, type: Hash, desc: 'User-Interactive Authentication data'
        end
        post :get_token do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
