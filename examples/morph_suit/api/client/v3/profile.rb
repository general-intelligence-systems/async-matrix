# frozen_string_literal: true

# /_matrix/client/v3/profile/:userId(/:keyName)
module MatrixApi
  module Client
    module V3
      class Profile < Base
        route_param :userId, type: String, desc: 'The user ID' do

          # GET /profile/:userId
          # Auth: no | Rate-limited: no | Response: 200, 403, 404
          desc 'Get the combined profile information for a user.' do
            failure [
              [403, 'Forbidden'],
              [404, 'User not found']
            ]
          end
          get do
            # TODO: implement
            status 200
          end

          route_param :keyName, type: String, desc: 'The profile field key' do

            # GET /profile/:userId/:keyName
            # Auth: no | Rate-limited: no | Response: 200, 403, 404
            desc 'Get a specific profile field for a user.' do
              failure [
                [403, 'Forbidden'],
                [404, 'User not found or key not set']
              ]
            end
            get do
              # TODO: implement
              status 200
            end

            # PUT /profile/:userId/:keyName
            # Auth: yes | Rate-limited: yes | Response: 200, 400, 403, 429
            desc 'Set a specific profile field.' do
              failure [
                [400, 'Bad request'],
                [403, 'Forbidden'],
                [429, 'Rate limited']
              ]
            end
            put do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            # DELETE /profile/:userId/:keyName
            # Auth: yes | Rate-limited: yes | Added v1.16 | Response: 200, 403, 429
            desc 'Delete a specific profile field.' do
              failure [
                [403, 'Forbidden'],
                [429, 'Rate limited']
              ]
            end
            delete do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end
          end
        end
      end
    end
  end
end
