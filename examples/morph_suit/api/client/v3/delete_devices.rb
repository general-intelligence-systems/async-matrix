# frozen_string_literal: true

# POST /_matrix/client/v3/delete_devices
# Auth: yes | Rate-limited: no | UIA
# Response: 200, 401
module MatrixApi
  module Client
    module V3
      class DeleteDevices < Base
        desc 'Bulk delete devices.' do
          detail 'Deletes the given devices and invalidates any associated access tokens.'
          failure [[401, 'Unauthorized / UIA required']]
        end
        params do
          requires :devices, type: Array[String], desc: 'List of device IDs to delete'
          optional :auth, type: Hash, desc: 'User-Interactive Authentication data'
        end
        post do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
