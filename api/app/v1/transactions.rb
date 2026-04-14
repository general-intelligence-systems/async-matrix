# frozen_string_literal: true

# PUT /_matrix/app/v1/transactions/:txnId
# Auth: yes (hs_token) | Rate-limited: no
# Response: 200
module MatrixApi
  module App
    module V1
      class Transactions < Base
        desc 'Push events from the homeserver to the application service.' do
          detail 'Batch of events with a transaction ID for idempotency.'
        end
        params do
          requires :events, type: Array, desc: 'List of events (ClientEvent format)'
          optional :ephemeral, type: Array, desc: 'Ephemeral data (m.presence, m.typing, m.receipt) (added v1.13)'
        end
        put ':txnId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
