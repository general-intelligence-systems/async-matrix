# frozen_string_literal: true

# GET /_matrix/client/v3/admin/whois/:userId
# Auth: yes | Rate-limited: no
# Response: 200
module MatrixApi
  module Client
    module V3
      class Admin < Base
        desc 'Get information about a user (admin).'
        get 'whois/:userId' do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
