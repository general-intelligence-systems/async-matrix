# frozen_string_literal: true

# GET /.well-known/matrix/client
# Auth: no | Rate-limited: no
# Response: 200, 404
module MatrixApi
  module WellKnown
    module Matrix
      class Client < Base
        desc 'Get homeserver discovery information.' do
          detail 'Returns discovery information about the domain.'
          failure [[404, 'No discovery information available']]
        end
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
