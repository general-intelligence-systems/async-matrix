# frozen_string_literal: true

# /_matrix/client/v3/publicRooms
module MatrixApi
  module Client
    module V3
      class PublicRooms < Base
        # GET /publicRooms
        # Auth: optional | Rate-limited: no | Response: 200
        desc 'List the public rooms on the server.'
        params do
          optional :limit, type: Integer, desc: 'Max results'
          optional :since, type: String, desc: 'Pagination token'
          optional :server, type: String, desc: 'Server to fetch from'
        end
        get do
          # TODO: implement
          status 200
        end

        # POST /publicRooms
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'List the public rooms on the server with filter.'
        params do
          optional :limit, type: Integer, desc: 'Max results'
          optional :since, type: String, desc: 'Pagination token'
          optional :filter, type: Hash, desc: 'Filter to apply'
          optional :include_all_networks, type: Boolean, desc: 'Include all networks'
          optional :third_party_instance_id, type: String, desc: 'Third-party network to search'
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
