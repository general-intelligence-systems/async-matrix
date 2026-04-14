# frozen_string_literal: true

# /_matrix/client/v1/admin/*
# Lock and suspend endpoints (Added v1.18)
module MatrixApi
  module Client
    module V1
      class Admin < Base
        # GET/PUT /admin/lock/:userId
        namespace :lock do
          route_param :userId, type: String, desc: 'The user ID' do

            # GET /admin/lock/:userId
            # Auth: yes | Rate-limited: yes | Response: 200, 403, 429
            desc 'Get whether a user is locked.' do
              failure [
                [403, 'Forbidden'],
                [429, 'Rate limited']
              ]
            end
            get do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            # PUT /admin/lock/:userId
            # Response: 200, 403, 429
            desc 'Lock or unlock a user.' do
              failure [
                [403, 'Forbidden'],
                [429, 'Rate limited']
              ]
            end
            params do
              requires :locked, type: Boolean, desc: 'Whether the user should be locked'
            end
            put do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end
          end
        end

        # GET/PUT /admin/suspend/:userId
        namespace :suspend do
          route_param :userId, type: String, desc: 'The user ID' do

            # GET /admin/suspend/:userId
            # Auth: yes | Rate-limited: yes | Response: 200, 403, 429
            desc 'Get whether a user is suspended.' do
              failure [
                [403, 'Forbidden'],
                [429, 'Rate limited']
              ]
            end
            get do
              authenticate!
              rate_limit!
              # TODO: implement
              status 200
            end

            # PUT /admin/suspend/:userId
            # Response: 200, 403, 429
            desc 'Suspend or unsuspend a user.' do
              failure [
                [403, 'Forbidden'],
                [429, 'Rate limited']
              ]
            end
            params do
              requires :suspended, type: Boolean, desc: 'Whether the user should be suspended'
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
