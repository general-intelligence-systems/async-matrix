# frozen_string_literal: true

# GET /_matrix/client/v1/register/m.login.registration_token/validity
# Auth: no | Rate-limited: yes | Added v1.2
# Response: 200, 403, 429
module MatrixApi
  module Client
    module V1
      class Register < Base
        namespace 'm.login.registration_token' do
          desc 'Check validity of a registration token.' do
            failure [
              [403, 'Forbidden'],
              [429, 'Rate limited']
            ]
          end
          params do
            requires :token, type: String, desc: 'The registration token to check'
          end
          get :validity do
            rate_limit!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
