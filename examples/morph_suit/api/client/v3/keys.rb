# frozen_string_literal: true

# /_matrix/client/v3/keys/*
module MatrixApi
  module Client
    module V3
      class Keys < Base
        # POST /keys/upload
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Upload end-to-end encryption keys.'
        params do
          optional :device_keys, type: Hash, desc: 'Identity keys for the device'
          optional :one_time_keys, type: Hash, desc: 'One-time public keys'
          optional :fallback_keys, type: Hash, desc: 'Fallback public keys (added v1.2)'
        end
        post :upload do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /keys/query
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Download device identity keys.'
        params do
          optional :timeout, type: Integer, desc: 'Max time to wait (ms)'
          requires :device_keys, type: Hash, desc: 'Map of userId => [deviceIds]'
          optional :token, type: String, desc: 'Sync token'
        end
        post :query do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /keys/claim
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Claim one-time encryption keys.'
        params do
          optional :timeout, type: Integer, desc: 'Max time to wait (ms)'
          requires :one_time_keys, type: Hash, desc: 'Map of userId => { deviceId => algorithm }'
        end
        post :claim do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /keys/changes
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Get users whose devices have changed.'
        params do
          requires :from, type: String, desc: 'Start sync token'
          requires :to, type: String, desc: 'End sync token'
        end
        get :changes do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /keys/device_signing/upload
        # Auth: yes | Rate-limited: no | UIA | Response: 200, 400, 401
        namespace :device_signing do
          desc 'Upload cross-signing keys.' do
            failure [
              [400, 'Bad request'],
              [401, 'Unauthorized / UIA required']
            ]
          end
          params do
            optional :auth, type: Hash, desc: 'UIA data'
            optional :master_key, type: Hash
            optional :self_signing_key, type: Hash
            optional :user_signing_key, type: Hash
          end
          post :upload do
            authenticate!
            # TODO: implement
            status 200
          end
        end

        # POST /keys/signatures/upload
        # Auth: yes | Rate-limited: no | Response: 200
        namespace :signatures do
          desc 'Upload cross-signing signatures.'
          post :upload do
            authenticate!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
