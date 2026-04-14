# frozen_string_literal: true

# POST /_matrix/identity/v2/lookup
# Auth: yes | Rate-limited: no
# Response: 200, 400
module MatrixApi
  module Identity
    module V2
      class Lookup < Base
        desc 'Look up Matrix User IDs bound to 3PIDs.' do
          failure [[400, 'Invalid request (M_INVALID_PEPPER, M_INVALID_PARAM)']]
        end
        params do
          requires :addresses, type: Array[String], desc: 'The addresses to look up (hashed or cleartext depending on algorithm)'
          requires :algorithm, type: String, desc: 'The algorithm used to encode addresses (sha256, none)'
          requires :pepper, type: String, desc: 'The pepper from /hash_details'
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
