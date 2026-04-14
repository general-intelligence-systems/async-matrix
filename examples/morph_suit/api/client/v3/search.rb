# frozen_string_literal: true

# POST /_matrix/client/v3/search
# Auth: yes | Rate-limited: yes
# Response: 200, 400, 429
module MatrixApi
  module Client
    module V3
      class Search < Base
        desc 'Perform a server-side search.' do
          failure [
            [400, 'Bad request'],
            [429, 'Rate limited']
          ]
        end
        params do
          optional :next_batch, type: String, desc: 'Pagination token'
          requires :search_categories, type: Hash, desc: 'Search categories'
        end
        post do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
