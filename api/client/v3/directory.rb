# frozen_string_literal: true

# /_matrix/client/v3/directory/*
# Room alias resolution + room directory visibility
module MatrixApi
  module Client
    module V3
      class Directory < Base

        # /directory/room/:roomAlias
        namespace :room do
          route_param :roomAlias, type: String, desc: 'The room alias' do

            # GET /directory/room/:roomAlias
            # Auth: no | Rate-limited: no | Response: 200, 404
            desc 'Get the room ID for an alias.' do
              failure [[404, 'Alias not found']]
            end
            get do
              # TODO: implement
              status 200
            end

            # PUT /directory/room/:roomAlias
            # Auth: yes | Rate-limited: no | Response: 200, 400, 403, 409
            desc 'Create a room alias.' do
              failure [
                [400, 'Bad request'],
                [403, 'Forbidden'],
                [409, 'Alias already taken']
              ]
            end
            params do
              requires :room_id, type: String, desc: 'The room ID to map to'
            end
            put do
              authenticate!
              # TODO: implement
              status 200
            end

            # DELETE /directory/room/:roomAlias
            # Auth: yes | Rate-limited: no | Response: 200, 404
            desc 'Delete a room alias.' do
              failure [[404, 'Alias not found']]
            end
            delete do
              authenticate!
              # TODO: implement
              status 200
            end
          end
        end

        # /directory/list/room/:roomId
        namespace :list do
          namespace :room do
            route_param :roomId, type: String, desc: 'The room ID' do

              # GET /directory/list/room/:roomId
              # Auth: no | Rate-limited: no | Response: 200, 404
              desc 'Get the visibility of a room in the directory.' do
                failure [[404, 'Room not found']]
              end
              get do
                # TODO: implement
                status 200
              end

              # PUT /directory/list/room/:roomId
              # Auth: yes | Rate-limited: yes | Response: 200, 404, 429
              desc 'Set the visibility of a room in the directory.' do
                failure [
                  [404, 'Room not found'],
                  [429, 'Rate limited']
                ]
              end
              params do
                optional :visibility, type: String, values: %w[public private], desc: 'Visibility'
              end
              put do
                authenticate!
                rate_limit!
                # TODO: implement
                status 200
              end
            end
          end

          # PUT /directory/list/appservice/:networkId/:roomId
          # Auth: yes (as_token) | Rate-limited: no
          # Response: 200
          # Application Service API extension
          namespace :appservice do
            desc 'Update room visibility in an appservice\'s directory.' do
              detail 'Sets whether a room is visible in the appservice\'s published room directory for the given network.'
            end
            params do
              requires :visibility, type: String, values: %w[public private], desc: 'Whether the room should be visible'
            end
            put ':networkId/:roomId' do
              authenticate!
              # TODO: implement
              status 200
            end
          end
        end

      end
    end
  end
end
