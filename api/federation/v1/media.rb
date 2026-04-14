# frozen_string_literal: true

# /_matrix/federation/v1/media/*
module MatrixApi
  module Federation
    module V1
      class Media < Base
        # GET /media/download/:mediaId
        # Auth: yes | Rate-limited: yes
        # Response: 200, 429, 502, 504
        desc 'Download content from this server over federation.' do
          failure [
            [429, 'Rate limited'],
            [502, 'Content too large to serve'],
            [504, 'Content not yet uploaded (M_NOT_YET_UPLOADED)']
          ]
        end
        params do
          optional :timeout_ms, type: Integer, desc: 'Max time to wait for content (ms)'
        end
        get 'download/:mediaId' do
          authenticate!
          rate_limit!
          # TODO: implement - returns multipart/mixed
          status 200
        end

        # GET /media/thumbnail/:mediaId
        # Auth: yes | Rate-limited: yes
        # Response: 200, 400, 413, 429, 502, 504
        desc 'Download a thumbnail over federation.' do
          failure [
            [400, 'Bad request'],
            [413, 'Content too large to thumbnail'],
            [429, 'Rate limited'],
            [502, 'Remote content too large'],
            [504, 'Content not yet uploaded']
          ]
        end
        params do
          requires :width, type: Integer, desc: 'Desired width'
          requires :height, type: Integer, desc: 'Desired height'
          optional :method, type: String, values: %w[crop scale], desc: 'Resizing method'
          optional :animated, type: Boolean, desc: 'Prefer animated thumbnails (added v1.11)'
          optional :timeout_ms, type: Integer, desc: 'Max time to wait (ms)'
        end
        get 'thumbnail/:mediaId' do
          authenticate!
          rate_limit!
          # TODO: implement - returns multipart/mixed
          status 200
        end
      end
    end
  end
end
