# frozen_string_literal: true

# /_matrix/client/v3/user_directory/search
module MatrixApi
  module Client
    module V3
      class UserDirectory < Base
        # POST /user_directory/search
        # Auth: yes | Rate-limited: yes | Response: 200, 429
        desc 'Search users in the user directory.' do
          failure [[429, 'Rate limited']]
        end
        params do
          requires :search_term, type: String, desc: 'The search term'
          optional :limit, type: Integer, desc: 'Maximum results'
          optional :language, type: String, desc: 'Language tag (added v1.18)'
        end
        post :search do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
