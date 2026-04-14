# frozen_string_literal: true

# GET /.well-known/matrix/support
# Auth: no | Rate-limited: no | Added v1.10
# Response: 200, 404
module MatrixApi
  module WellKnown
    module Matrix
      class Support < Base
        desc 'Get homeserver admin contact and support page.' do
          detail 'Returns server admin contact and support page URI.'
          failure [[404, 'No support information available']]
        end
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
