# frozen_string_literal: true

# /_matrix/federation/v1/query/*
module MatrixApi
  module Federation
    module V1
      class Query < Base
        # GET /query/directory
        # Auth: yes | Rate-limited: no
        # Response: 200, 404
        desc 'Query for a room alias -> room ID mapping.' do
          failure [[404, 'Room alias not found']]
        end
        params do
          requires :room_alias, type: String, desc: 'The room alias to look up'
        end
        get :directory do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /query/profile
        # Auth: yes | Rate-limited: no
        # Response: 200, 403, 404
        desc 'Query for a user\'s profile.' do
          failure [
            [403, 'Server refuses to disclose profile'],
            [404, 'User does not exist']
          ]
        end
        params do
          requires :user_id, type: String, desc: 'The user ID to query'
          optional :field, type: String, desc: 'Specific field (displayname, avatar_url)'
        end
        get :profile do
          authenticate!
          # TODO: implement
          status 200
        end

        # GET /query/:queryType - Generic query
        # Auth: yes | Rate-limited: no
        # Response: 200
        desc 'Perform a generic query on the server.'
        get ':queryType' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
