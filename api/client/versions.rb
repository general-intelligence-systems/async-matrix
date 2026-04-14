# frozen_string_literal: true

# GET /_matrix/client/versions
# Auth: optional | Rate-limited: no
# Response: 200
module MatrixApi
  module Client
    class Versions < Base
      desc 'Get the versions of the client-server API supported by this server.' do
        detail 'Returns the list of supported Matrix client-server API versions.'
      end
      get do
        # TODO: implement
        status 200
      end
    end
  end
end
