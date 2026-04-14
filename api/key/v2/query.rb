# frozen_string_literal: true

# /_matrix/key/v2/query
module MatrixApi
  module Key
    module V2
      class Query < Base
        # POST /query - Batch query for keys from multiple servers
        # Auth: no | Rate-limited: no
        # Response: 200
        desc 'Query for keys from multiple servers in a batch format.' do
          detail 'The notary server must sign the keys returned by the queried servers.'
        end
        params do
          requires :server_keys, type: Hash, desc: 'Map of server name to key ID to QueryCriteria'
        end
        post do
          # TODO: implement
          status 200
        end

        # GET /query/:serverName - Query keys for a single server
        # Auth: no | Rate-limited: no
        # Response: 200
        desc 'Query for another server\'s keys.' do
          detail 'The notary server must sign the keys returned by the queried server.'
        end
        params do
          optional :minimum_valid_until_ts, type: Integer, desc: 'Keys should be valid until at least this POSIX timestamp (ms)'
        end
        get ':serverName' do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
