# frozen_string_literal: true

# POST /_matrix/policy/v1/sign
# Auth: yes | Rate-limited: yes | Added v1.18
# Response: 200, 400, 403, 404, 429
module MatrixApi
  module Policy
    module V1
      class Sign < Base
        desc 'Ask for a Policy Server signature on an event.' do
          detail 'The body is the PDU to be signed. Returns a signature map.'
          failure [
            [400, 'Invalid request or PS refuses to sign (M_BAD_JSON, M_NOT_JSON, M_FORBIDDEN)'],
            [403, 'ACL\'d (M_FORBIDDEN)'],
            [404, 'Not a PS / unknown room (M_NOT_FOUND, M_UNRECOGNIZED)'],
            [429, 'Rate limited']
          ]
        end
        post do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
