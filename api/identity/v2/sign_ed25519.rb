# frozen_string_literal: true

# POST /_matrix/identity/v2/sign-ed25519
# Auth: yes | Rate-limited: no
# Response: 200, 403, 404
module MatrixApi
  module Identity
    module V2
      class SignEd25519 < Base
        desc 'Sign invitation details with an ed25519 key.' do
          detail 'Looks up the stored invite token and signs the invitation details.'
          failure [
            [403, 'Must accept terms (M_TERMS_NOT_SIGNED)'],
            [404, 'Token not found (M_UNRECOGNIZED)']
          ]
        end
        params do
          requires :mxid, type: String, desc: 'Matrix user ID of the user accepting the invitation'
          requires :private_key, type: String, desc: 'Unpadded Base64-encoded private key'
          requires :token, type: String, desc: 'The token from store-invite'
        end
        post do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
