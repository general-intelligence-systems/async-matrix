# frozen_string_literal: true

# /_matrix/federation/v1/publicRooms
module MatrixApi
  module Federation
    module V1
      class PublicRooms < Base
        # GET /publicRooms
        # Auth: yes | Rate-limited: no
        # Response: 200
        desc 'Get the public room list for this server.'
        params do
          optional :limit, type: Integer, desc: 'Max results (0 = no limit)'
          optional :since, type: String, desc: 'Pagination token'
          optional :include_all_networks, type: Boolean, desc: 'Include all networks'
          optional :third_party_instance_id, type: String, desc: 'Specific network'
        end
        get do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /publicRooms
        # Auth: yes | Rate-limited: no
        # Response: 200
        desc 'Get the public room list with filtering.'
        params do
          optional :limit, type: Integer, desc: 'Max results'
          optional :since, type: String, desc: 'Pagination token'
          optional :filter, type: Hash, desc: 'Filter (generic_search_term, room_types)'
          optional :include_all_networks, type: Boolean, desc: 'Include all networks'
          optional :third_party_instance_id, type: String, desc: 'Specific network'
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
