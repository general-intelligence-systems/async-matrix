# frozen_string_literal: true

# /_matrix/app/v1/thirdparty/*
# All auth: yes (hs_token) | Rate-limited: no
# All responses: 200, 401, 403, 404
module MatrixApi
  module App
    module V1
      class Thirdparty < Base

        THIRDPARTY_ERRORS = [
          [401, 'Homeserver has not supplied credentials'],
          [403, 'Credentials rejected'],
          [404, 'No mappings found']
        ].freeze

        # GET /thirdparty/protocol/:protocol
        # Response: 200, 401, 403, 404
        desc 'Get metadata about a third-party protocol.' do
          failure THIRDPARTY_ERRORS
        end
        get 'protocol/:protocol' do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/location
        # Response: 200, 401, 403, 404
        desc 'Retrieve third-party locations from a Matrix room alias.' do
          failure THIRDPARTY_ERRORS
        end
        params do
          optional :alias, type: String, desc: 'The Matrix room alias to look up'
        end
        get :location do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/location/:protocol
        # Response: 200, 401, 403, 404
        desc 'Retrieve third-party locations for a protocol.' do
          failure THIRDPARTY_ERRORS
        end
        params do
          # Additional protocol-specific fields passed as query params
        end
        get 'location/:protocol' do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/user
        # Response: 200, 401, 403, 404
        desc 'Retrieve third-party users from a Matrix User ID.' do
          failure THIRDPARTY_ERRORS
        end
        params do
          optional :userid, type: String, desc: 'The Matrix User ID to look up'
        end
        get :user do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /thirdparty/user/:protocol
        # Response: 200, 401, 403, 404
        desc 'Retrieve third-party users for a protocol.' do
          failure THIRDPARTY_ERRORS
        end
        params do
          # Additional protocol-specific fields passed as query params
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
