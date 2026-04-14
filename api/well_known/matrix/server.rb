# frozen_string_literal: true

# GET /.well-known/matrix/server
# Auth: no | Rate-limited: no
# Response: 200
module MatrixApi
  module WellKnown
    module Matrix
      class Server < Base
        desc 'Get delegated server information for federation.' do
          detail 'Returns server name for server-server communication delegation.'
        end
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
