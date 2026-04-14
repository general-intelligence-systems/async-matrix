# frozen_string_literal: true

# PUT /_matrix/client/v3/sendToDevice/:eventType/:txnId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Client
    module V3
      class SendToDevice < Base
        desc 'Send an event to one or more devices.'
        params do
          requires :messages, type: Hash, desc: 'Map of userId => { deviceId|"*" => content }'
        end
        put ':eventType/:txnId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
