# frozen_string_literal: true

# /_matrix/identity/v2/pubkey/*
# All auth: no | Rate-limited: no
module MatrixApi
  module Identity
    module V2
      class Pubkey < Base
        # GET /pubkey/ephemeral/isvalid
        # Response: 200
        desc 'Check whether a short-term public key is valid.'
        params do
          requires :public_key, type: String, desc: 'Unpadded Base64-encoded public key'
        end
        get 'ephemeral/isvalid' do
          # TODO: implement
          status 200
        end

        # GET /pubkey/isvalid
        # Response: 200
        desc 'Check whether a long-term public key is valid.'
        params do
          requires :public_key, type: String, desc: 'Unpadded Base64-encoded public key'
        end
        get :isvalid do
          # TODO: implement
          status 200
        end

        # GET /pubkey/:keyId
        # Response: 200, 404
        desc 'Get the public key for the given key ID.' do
          failure [[404, 'Public key not found']]
        end
        get ':keyId' do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
