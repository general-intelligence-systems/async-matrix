# frozen_string_literal: true

# GET /_matrix/client/v3/sync
# Auth: yes | Rate-limited: no
# Response: 200, 429
module MatrixApi
  module Client
    module V3
      class Sync < Base
        desc 'Synchronise the client state with the latest known server state.' do
          detail 'Long-poll endpoint for syncing. Returns events since the given since token.'
          failure [[429, 'Rate limited (M_LIMIT_EXCEEDED, only on initial sync)']]
        end
        params do
          optional :filter, type: String, desc: 'Filter ID or inline JSON filter'
          optional :since, type: String, desc: 'A point in time to continue sync from (next_batch token)'
          optional :full_state, type: Boolean, desc: 'Return full state for all rooms'
          optional :set_presence, type: String, values: %w[offline online unavailable], desc: 'Presence state to set'
          optional :timeout, type: Integer, desc: 'Maximum wait time in milliseconds for long-polling'
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
