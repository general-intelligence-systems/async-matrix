# frozen_string_literal: true

# /_matrix/client/v3/user/:userId/*
# Covers: filter, account_data, room account_data, tags, openid
module MatrixApi
  module Client
    module V3
      class User < Base
        route_param :userId, type: String, desc: 'The user ID' do

          # POST /user/:userId/filter
          # Auth: yes | Rate-limited: no
          # Response: 200
          namespace :filter do
            desc 'Upload a new filter definition.'
            params do
              optional :account_data, type: Hash, desc: 'Account data event filter'
              optional :event_fields, type: Array[String], desc: 'Fields to include in events'
              optional :event_format, type: String, values: %w[client federation], desc: 'Event format'
              optional :presence, type: Hash, desc: 'Presence event filter'
              optional :room, type: Hash, desc: 'Room filter definition'
            end
            post do
              authenticate!
              # TODO: implement
              status 200
            end

            # GET /user/:userId/filter/:filterId
            # Auth: yes | Rate-limited: no
            # Response: 200, 404
            desc 'Download a previously uploaded filter.' do
              failure [[404, 'Filter not found']]
            end
            get ':filterId' do
              authenticate!
              # TODO: implement
              status 200
            end
          end

          # GET/PUT /user/:userId/account_data/:type
          namespace :account_data do
            route_param :type, type: String, desc: 'The event type of the account data' do

              # GET /user/:userId/account_data/:type
              # Auth: yes | Rate-limited: no
              # Response: 200, 403, 404
              desc 'Get account data for the user.' do
                failure [
                  [403, 'Forbidden'],
                  [404, 'Account data not found']
                ]
              end
              get do
                authenticate!
                # TODO: implement
                status 200
              end

              # PUT /user/:userId/account_data/:type
              # Auth: yes | Rate-limited: no
              # Response: 200, 400, 403, 405
              desc 'Set account data for the user.' do
                failure [
                  [400, 'Bad request'],
                  [403, 'Forbidden'],
                  [405, 'Cannot set this type of account data']
                ]
              end
              put do
                authenticate!
                # TODO: implement
                status 200
              end
            end
          end

          # /user/:userId/rooms/:roomId/*
          namespace :rooms do
            route_param :roomId, type: String, desc: 'The room ID' do

              # GET/PUT /user/:userId/rooms/:roomId/account_data/:type
              namespace :account_data do
                route_param :type, type: String, desc: 'The event type' do

                  # GET
                  # Auth: yes | Rate-limited: no
                  # Response: 200, 403, 404
                  desc 'Get per-room account data.' do
                    failure [
                      [403, 'Forbidden'],
                      [404, 'Account data not found']
                    ]
                  end
                  get do
                    authenticate!
                    # TODO: implement
                    status 200
                  end

                  # PUT
                  # Auth: yes | Rate-limited: no
                  # Response: 200, 400, 403, 405
                  desc 'Set per-room account data.' do
                    failure [
                      [400, 'Bad request'],
                      [403, 'Forbidden'],
                      [405, 'Cannot set this type']
                    ]
                  end
                  put do
                    authenticate!
                    # TODO: implement
                    status 200
                  end
                end
              end

              # GET/PUT/DELETE /user/:userId/rooms/:roomId/tags(/:tag)
              namespace :tags do
                # GET /user/:userId/rooms/:roomId/tags
                # Auth: yes | Rate-limited: no
                # Response: 200
                desc 'List the tags set on a room by the user.'
                get do
                  authenticate!
                  # TODO: implement
                  status 200
                end

                route_param :tag, type: String, desc: 'The tag name' do
                  # PUT /user/:userId/rooms/:roomId/tags/:tag
                  # Auth: yes | Rate-limited: no
                  # Response: 200
                  desc 'Add a tag to a room.'
                  params do
                    optional :order, type: Float, desc: 'Ordering info (number between 0 and 1)'
                  end
                  put do
                    authenticate!
                    # TODO: implement
                    status 200
                  end

                  # DELETE /user/:userId/rooms/:roomId/tags/:tag
                  # Auth: yes | Rate-limited: no
                  # Response: 200
                  desc 'Remove a tag from a room.'
                  delete do
                    authenticate!
                    # TODO: implement
                    status 200
                  end
                end
              end

            end # route_param :roomId
          end # namespace :rooms

          # POST /user/:userId/openid/request_token
          # Auth: yes | Rate-limited: yes
          # Response: 200, 429
          namespace :openid do
            desc 'Request an OpenID token.' do
              detail 'Gets an OpenID token object that the requester may supply to another service.'
              failure [[429, 'Rate limited (M_LIMIT_EXCEEDED)']]
            end
            post :request_token do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end
          end

        end # route_param :userId
      end
    end
  end
end
