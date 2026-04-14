# frozen_string_literal: true

# /_matrix/identity/v2/account/*
module MatrixApi
  module Identity
    module V2
      class Account < Base
        # GET /account
        # Auth: yes | Rate-limited: no
        # Response: 200, 403
        desc 'Get information about the token owner.' do
          failure [[403, 'Must accept terms (M_TERMS_NOT_SIGNED)']]
        end
        get do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /account/logout
        # Auth: yes | Rate-limited: no
        # Response: 200, 401, 403
        desc 'Log out the access token.' do
          failure [
            [401, 'Token unknown (M_UNKNOWN_TOKEN)'],
            [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
          ]
        end
        post :logout do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /account/register
        # Auth: no | Rate-limited: no
        # Response: 200
        desc 'Exchange an OpenID token for an identity server access token.'
        params do
          requires :access_token, type: String, desc: 'OpenID access token from homeserver'
          requires :expires_in, type: Integer, desc: 'Seconds until token expires'
          requires :matrix_server_name, type: String, desc: 'Homeserver domain to verify against'
          requires :token_type, type: String, desc: 'The string "Bearer"'
        end
        post :register do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
