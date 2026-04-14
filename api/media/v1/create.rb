# frozen_string_literal: true

# POST /_matrix/media/v1/create
# Auth: yes | Rate-limited: yes | Added v1.7
# Response: 200, 403, 429
module MatrixApi
  module Media
    module V1
      class Create < Base
        desc 'Create an MXC URI without uploading content.' do
          detail 'Creates a new MXC URI that can later be populated with PUT upload.'
          failure [
            [403, 'Forbidden'],
            [429, 'Rate limited']
          ]
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
