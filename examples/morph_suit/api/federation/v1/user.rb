# frozen_string_literal: true

# /_matrix/federation/v1/user/*
module MatrixApi
  module Federation
    module V1
      class User < Base
        # GET /user/devices/:userId
        # Auth: yes | Rate-limited: no
        # Response: 200
        namespace :devices do
          desc 'Get a user\'s devices and identity keys.'
          get ':userId' do
            authenticate!
            # TODO: implement
            status 200
          end
        end

        namespace :keys do
          # POST /user/keys/claim
          # Auth: yes | Rate-limited: no
          # Response: 200
          desc 'Claim one-time keys for users on this server.'
          params do
            requires :one_time_keys, type: Hash, desc: 'Map of userId => { deviceId => algorithm }'
          end
          post :claim do
            authenticate!
            # TODO: implement
            status 200
          end

          # POST /user/keys/query
          # Auth: yes | Rate-limited: no
          # Response: 200
          desc 'Query device keys for users on this server.'
          params do
            requires :device_keys, type: Hash, desc: 'Map of userId => [deviceIds] (empty = all)'
          end
          post :query do
            authenticate!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
