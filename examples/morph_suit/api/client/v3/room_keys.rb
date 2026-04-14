# frozen_string_literal: true

# /_matrix/client/v3/room_keys/*
# Key backup endpoints
module MatrixApi
  module Client
    module V3
      class RoomKeys < Base

        # ================================================================
        # /room_keys/version
        # ================================================================
        namespace :version do
          # GET /room_keys/version - latest backup
          # Auth: yes | Rate-limited: yes | Response: 200, 404
          desc 'Get the latest backup version.' do
            failure [[404, 'No backup exists']]
          end
          get do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /room_keys/version - create
          # Auth: yes | Rate-limited: yes | Response: 200
          desc 'Create a new backup version.'
          params do
            requires :algorithm, type: String, desc: 'Backup algorithm'
            requires :auth_data, type: Hash, desc: 'Algorithm-dependent data'
          end
          post do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          route_param :version, type: String, desc: 'The backup version' do
            # GET /room_keys/version/:version
            # Response: 200, 404
            desc 'Get info about an existing backup.' do
              failure [[404, 'Not found']]
            end
            get do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            # PUT /room_keys/version/:version
            # Response: 200, 404
            desc 'Update info about an existing backup.' do
              failure [[404, 'Not found']]
            end
            params do
              requires :algorithm, type: String
              requires :auth_data, type: Hash
            end
            put do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            # DELETE /room_keys/version/:version
            # Response: 200, 404
            desc 'Delete an existing key backup.' do
              failure [[404, 'Not found']]
            end
            delete do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end
          end
        end

        # ================================================================
        # /room_keys/keys
        # ================================================================
        namespace :keys do
          # GET /room_keys/keys
          # Auth: yes | Rate-limited: yes | Response: 200, 404
          desc 'Retrieve all keys from backup.' do
            failure [[404, 'Not found']]
          end
          params do
            requires :version, type: String, desc: 'Backup version'
          end
          get do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # PUT /room_keys/keys
          # Response: 200, 403, 404
          desc 'Store keys in the backup.' do
            failure [
              [403, 'Wrong backup version'],
              [404, 'Not found']
            ]
          end
          params do
            requires :version, type: String
          end
          put do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # DELETE /room_keys/keys
          # Response: 200, 404
          desc 'Delete all keys from the backup.' do
            failure [[404, 'Not found']]
          end
          params do
            requires :version, type: String
          end
          delete do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          route_param :roomId, type: String, desc: 'The room ID' do
            # GET/PUT/DELETE /room_keys/keys/:roomId
            desc 'Retrieve keys from backup for a room.' do
              failure [[404, 'Not found']]
            end
            params do
              requires :version, type: String
            end
            get do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            desc 'Store keys for a room.' do
              failure [[403, 'Wrong version'], [404, 'Not found']]
            end
            params do
              requires :version, type: String
            end
            put do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            desc 'Delete keys for a room.' do
              failure [[404, 'Not found']]
            end
            params do
              requires :version, type: String
            end
            delete do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            route_param :sessionId, type: String, desc: 'The session ID' do
              # GET/PUT/DELETE /room_keys/keys/:roomId/:sessionId
              desc 'Retrieve a key from backup.' do
                failure [[404, 'Not found']]
              end
              params do
                requires :version, type: String
              end
              get do
                authenticate!
                rate_limit!
                # TODO: implement
                status 200
              end

              desc 'Store a key in backup.' do
                failure [[403, 'Wrong version'], [404, 'Not found']]
              end
              params do
                requires :version, type: String
              end
              put do
                authenticate!
                rate_limit!
                # TODO: implement
                status 200
              end

              desc 'Delete a key from backup.' do
                failure [[404, 'Not found']]
              end
              params do
                requires :version, type: String
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
end
