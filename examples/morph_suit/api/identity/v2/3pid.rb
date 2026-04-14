# frozen_string_literal: true

# /_matrix/identity/v2/3pid/*
module MatrixApi
  module Identity
    module V2
      class ThreePid < Base
        # POST /3pid/bind
        # Auth: yes | Rate-limited: no
        # Response: 200, 400, 403, 404
        desc 'Publish an association between a 3PID and a Matrix user ID.' do
          failure [
            [400, 'Not validated or expired (M_SESSION_NOT_VALIDATED, M_SESSION_EXPIRED)'],
            [403, 'Must accept terms (M_TERMS_NOT_SIGNED)'],
            [404, 'Session not found (M_NO_VALID_SESSION)']
          ]
        end
        params do
          requires :client_secret, type: String, desc: 'Client secret from requestToken'
          requires :mxid, type: String, desc: 'Matrix user ID to associate'
          requires :sid, type: String, desc: 'Session ID from requestToken'
        end
        post :bind do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /3pid/getValidated3pid
        # Auth: yes | Rate-limited: no
        # Response: 200, 400, 403, 404
        desc 'Check if a 3PID has been validated.' do
          failure [
            [400, 'Not validated or expired (M_SESSION_NOT_VALIDATED, M_SESSION_EXPIRED)'],
            [403, 'Must accept terms (M_TERMS_NOT_SIGNED)'],
            [404, 'Session not found (M_NO_VALID_SESSION)']
          ]
        end
        params do
          requires :client_secret, type: String, desc: 'Client secret from requestToken'
          requires :sid, type: String, desc: 'Session ID from requestToken'
        end
        get :getValidated3pid do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /3pid/unbind
        # Auth: yes | Rate-limited: no
        # Response: 200, 400, 403, 404, 501
        desc 'Remove an association between a 3PID and a Matrix user ID.' do
          failure [
            [400, 'Error or unsupported'],
            [403, 'Invalid credentials or must accept terms'],
            [404, 'Not found or unsupported'],
            [501, 'Server does not support unbinds']
          ]
        end
        params do
          requires :mxid, type: String, desc: 'Matrix user ID to disassociate'
          requires :threepid, type: Hash, desc: 'The 3PID to remove (address, medium)'
          optional :client_secret, type: String, desc: 'Client secret (for session-based auth)'
          optional :sid, type: String, desc: 'Session ID (for session-based auth)'
        end
        post :unbind do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
