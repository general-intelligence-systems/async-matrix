# frozen_string_literal: true

# /_matrix/client/v1/media/*
# Authenticated media endpoints
module MatrixApi
  module Client
    module V1
      class Media < Base
        # GET /media/config
        # Auth: yes | Rate-limited: yes | Response: 200, 429
        desc 'Get the media repository configuration.' do
          failure [[429, 'Rate limited']]
        end
        get :config do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end

        # GET /media/download/:serverName/:mediaId(/:fileName)
        namespace :download do
          # GET /media/download/:serverName/:mediaId
          # Auth: yes | Rate-limited: yes | Response: 200, 429, 502, 504
          desc 'Download content from the content repository.' do
            failure [
              [429, 'Rate limited'],
              [502, 'Remote server error'],
              [504, 'Remote server timeout']
            ]
          end
          params do
            optional :timeout_ms, type: Integer, desc: 'Max time to wait for remote media (ms)'
          end
          get ':serverName/:mediaId' do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # GET /media/download/:serverName/:mediaId/:fileName
          desc 'Download content with a specified filename.' do
            failure [
              [429, 'Rate limited'],
              [502, 'Remote server error'],
              [504, 'Remote server timeout']
            ]
          end
          params do
            optional :timeout_ms, type: Integer, desc: 'Max time to wait (ms)'
          end
          get ':serverName/:mediaId/:fileName' do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end
        end

        # GET /media/preview_url
        # Auth: yes | Rate-limited: yes | Response: 200, 429
        desc 'Get a URL preview.' do
          failure [[429, 'Rate limited']]
        end
        params do
          requires :url, type: String, desc: 'The URL to preview'
          optional :ts, type: Integer, desc: 'Preferred point in time (Unix ms)'
        end
        get :preview_url do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end

        # GET /media/thumbnail/:serverName/:mediaId
        # Auth: yes | Rate-limited: yes | Response: 200, 400, 413, 429, 502, 504
        namespace :thumbnail do
          desc 'Download a thumbnail of content.' do
            failure [
              [400, 'Bad request'],
              [413, 'Thumbnail too large'],
              [429, 'Rate limited'],
              [502, 'Remote server error'],
              [504, 'Remote server timeout']
            ]
          end
          params do
            requires :width, type: Integer, desc: 'Desired width in pixels'
            requires :height, type: Integer, desc: 'Desired height in pixels'
            optional :method, type: String, values: %w[crop scale], desc: 'Resizing method'
            optional :timeout_ms, type: Integer, desc: 'Max time to wait (ms)'
            optional :animated, type: Boolean, desc: 'Prefer animated thumbnails (added v1.11)'
          end
          get ':serverName/:mediaId' do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
