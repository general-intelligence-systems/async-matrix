# frozen_string_literal: true

# GET /_matrix/identity/v2/hash_details
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Identity
    module V2
      class HashDetails < Base
        desc 'Get parameters for hashing identifiers.' do
          detail 'Returns supported algorithms and the current lookup pepper.'
        end
        get do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
