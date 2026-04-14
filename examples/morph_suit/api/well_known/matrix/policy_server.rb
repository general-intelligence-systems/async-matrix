# frozen_string_literal: true

# GET /.well-known/matrix/policy_server
# Auth: no | Rate-limited: no | Added v1.18
# Response: 200, 404
module MatrixApi
  module WellKnown
    module Matrix
      class PolicyServer < Base
        desc 'Get policy server public keys.' do
          detail 'Returns the public keys for the policy server.'
          failure [[404, 'No policy server configured']]
        end
        get do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
