# frozen_string_literal: true

# /_matrix/media/v3/upload
module MatrixApi
  module Media
    module V3
      class Upload < Base
        # POST /upload
        # Auth: yes | Rate-limited: yes
        # Response: 200, 403, 413, 429
        desc 'Upload content to the content repository.' do
          failure [
            [403, 'Forbidden'],
            [413, 'Content too large (M_TOO_LARGE)'],
            [429, 'Rate limited']
          ]
        end
        params do
          optional :filename, type: String, desc: 'Filename for the content'
        end
        post do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end

        # PUT /upload/:serverName/:mediaId
        # Auth: yes | Rate-limited: yes | Added v1.7
        # Response: 200, 403, 409, 413, 429
        desc 'Upload content to a previously created MXC URI.' do
          failure [
            [403, 'Forbidden'],
            [409, 'Content already uploaded'],
            [413, 'Content too large'],
            [429, 'Rate limited']
          ]
        end
        params do
          optional :filename, type: String, desc: 'Filename for the content'
        end
        put ':serverName/:mediaId' do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
