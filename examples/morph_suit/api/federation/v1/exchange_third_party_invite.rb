# frozen_string_literal: true

# PUT /_matrix/federation/v1/exchange_third_party_invite/:roomId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Federation
    module V1
      class ExchangeThirdPartyInvite < Base
        desc 'Exchange a third-party invite for a regular invite event.' do
          detail 'The resident server verifies the invite and issues a proper m.room.member invite.'
        end
        put ':roomId' do
          authenticate!
          # TODO: implement - body is m.room.member event with third_party_invite content
          status 200
        end
      end
    end
  end
end
