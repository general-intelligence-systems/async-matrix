# frozen_string_literal: true

# /_matrix/client/v3/presence/:userId/status
module MatrixApi
  module Client
    module V3
      class Presence < Base
        route_param :userId, type: String, desc: 'The user ID' do
          namespace :status do

            # GET /presence/:userId/status
            # Auth: yes | Rate-limited: no | Response: 200, 403, 404
            desc 'Get the presence status for a user.' do
              failure [
                [403, 'Forbidden'],
                [404, 'User not found']
              ]
            end
            get do
              authenticate!
              # TODO: implement
              status 200
            end

            # PUT /presence/:userId/status
            # Auth: yes | Rate-limited: yes | Response: 200, 429
            desc 'Set the presence status for the user.' do
              failure [[429, 'Rate limited']]
            end
            params do
              requires :presence, type: String, values: %w[online offline unavailable], desc: 'The presence state'
              optional :status_msg, type: String, desc: 'A human-readable status message'
            end
            put do
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
