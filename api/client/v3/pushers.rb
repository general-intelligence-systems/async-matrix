# frozen_string_literal: true

# /_matrix/client/v3/pushers
module MatrixApi
  module Client
    module V3
      class Pushers < Base
        # GET /pushers
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Get all pushers for the user.'
        get do
          authenticate!
          # TODO: implement
          status 200
        end

        # POST /pushers/set
        # Auth: yes | Rate-limited: yes | Response: 200, 400, 429
        desc 'Modify a pusher or create a new one.' do
          failure [
            [400, 'Bad request'],
            [429, 'Rate limited']
          ]
        end
        params do
          requires :pushkey, type: String, desc: 'Unique identifier for this pusher'
          requires :kind, type: String, desc: 'Pusher kind (http, email, or null to delete)'
          requires :app_id, type: String, desc: 'Application identifier'
          requires :app_display_name, type: String, desc: 'Application name'
          requires :device_display_name, type: String, desc: 'Device name'
          optional :profile_tag, type: String, desc: 'Profile tag'
          requires :lang, type: String, desc: 'Preferred language (ISO 639)'
          requires :data, type: Hash, desc: 'Dictionary of pusher data (url, format)'
          optional :append, type: Boolean, desc: 'Append to existing pushers'
        end
        post :set do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
