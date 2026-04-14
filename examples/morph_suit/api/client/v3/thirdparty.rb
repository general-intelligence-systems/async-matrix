# frozen_string_literal: true

# /_matrix/client/v3/thirdparty/*
module MatrixApi
  module Client
    module V3
      class Thirdparty < Base
        # GET /thirdparty/protocols
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Get metadata about all protocols.'
        get :protocols do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/protocol/:protocol
        # Auth: yes | Rate-limited: no | Response: 200, 404
        desc 'Get metadata about a specific protocol.' do
          failure [[404, 'Protocol not found']]
        end
        get 'protocol/:protocol' do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/location
        # Auth: yes | Rate-limited: no | Response: 200, 404
        desc 'Retrieve Matrix locations for a 3rd party alias.' do
          failure [[404, 'No mapping found']]
        end
        params do
          requires :alias, type: String, desc: 'The alias to look up'
        end
        get :location do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/location/:protocol
        # Auth: yes | Rate-limited: no | Response: 200, 404
        desc 'Retrieve Matrix locations for a 3rd party protocol.' do
          failure [[404, 'No mapping found']]
        end
        get 'location/:protocol' do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/user
        # Auth: yes | Rate-limited: no | Response: 200, 404
        desc 'Retrieve 3rd party users for a Matrix user ID.' do
          failure [[404, 'No mapping found']]
        end
        params do
          requires :userid, type: String, desc: 'The Matrix user ID'
        end
        get :user do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/user/:protocol
        # Auth: yes | Rate-limited: no | Response: 200, 404
        desc 'Retrieve 3rd party users for a given protocol.' do
          failure [[404, 'No mapping found']]
        end
        get 'user/:protocol' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
