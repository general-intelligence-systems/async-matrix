# frozen_string_literal: true

# /_matrix/client/v3/devices(/:deviceId)
module MatrixApi
  module Client
    module V3
      class Devices < Base
        # GET /devices
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'List all registered devices for the user.'
        get do
          authenticate!
          # TODO: implement
          status 200
        end

        route_param :deviceId, type: String, desc: 'The device ID' do
          # GET /devices/:deviceId
          # Auth: yes | Rate-limited: no | Response: 200, 404
          desc 'Get information on a single device.' do
            failure [[404, 'Device not found']]
          end
          get do
            authenticate!
            # TODO: implement
            status 200
          end

          # PUT /devices/:deviceId
          # Auth: yes | Rate-limited: no | Response: 200, 404
          desc 'Update a device.' do
            failure [[404, 'Device not found']]
          end
          params do
            optional :display_name, type: String, desc: 'The new display name for the device'
          end
          put do
            authenticate!
            # TODO: implement
            status 200
          end

          # DELETE /devices/:deviceId
          # Auth: yes | Rate-limited: no | UIA | Response: 200, 401
          desc 'Delete a device.' do
            failure [[401, 'Unauthorized / UIA required']]
          end
          params do
            optional :auth, type: Hash, desc: 'User-Interactive Authentication data'
          end
          delete do
            authenticate!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
