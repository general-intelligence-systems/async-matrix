# frozen_string_literal: true

# GET /_matrix/identity/versions
# Auth: no | Rate-limited: no | Added v1.1
# Response: 200
module MatrixApi
  module Identity
    class Versions < Base
      desc 'Get the versions of the specification supported by the server.'
      get do
        # TODO: implement
        status 200
      end
    end
  end
end
