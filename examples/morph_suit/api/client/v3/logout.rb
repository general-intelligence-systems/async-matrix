# frozen_string_literal: true

# /_matrix/client/v3/logout
module MatrixApi
  module Client
    module V3
      class Logout < Base
        # POST /logout - Invalidate current access token
        # Auth: yes | Rate-limited: no
        # Response: 200
        desc 'Invalidate the current access token.' do
          detail 'Invalidates the access token, logging the user out of this session.'
        end
        post do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /logout/all - Invalidate all access tokens
        # Auth: yes | Rate-limited: no
        # Response: 200
        desc 'Invalidate all access tokens for the user.' do
          detail 'Invalidates all access tokens, logging the user out everywhere.'
        end
        post :all do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
