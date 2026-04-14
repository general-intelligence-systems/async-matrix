# frozen_string_literal: true

# PUT /_matrix/federation/v1/send/:txnId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class Send < Base
        desc 'Push messages (transaction) to another server.' do
          detail 'PDUs and EDUs wrapped in a Transaction. Max 50 PDUs, 100 EDUs.'
        end
        params do
          requires :origin, type: String, desc: 'The server_name of the sending homeserver'
          requires :origin_server_ts, type: Integer, desc: 'POSIX timestamp (ms) when transaction started'
          requires :pdus, type: Array, desc: 'List of persistent updates (max 50)'
          optional :edus, type: Array, desc: 'List of ephemeral messages (max 100)'
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
