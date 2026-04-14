# frozen_string_literal: true

# GET /_matrix/client/v1/auth_metadata
# Auth: no | Rate-limited: no | Added v1.15
# Response: 200, 404
module MatrixApi
  module Client
    module V1
      class AuthMetadata < Base
        desc 'Get OAuth 2.0 authorization server metadata.' do
          detail 'Returns the OAuth 2.0 Authorization Server Metadata.'
          failure [[404, 'Not found (M_UNRECOGNIZED)']]
        end
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
