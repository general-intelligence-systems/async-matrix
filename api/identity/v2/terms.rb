# frozen_string_literal: true

# /_matrix/identity/v2/terms
module MatrixApi
  module Identity
    module V2
      class Terms < Base
        # GET /terms
        # Auth: no | Rate-limited: no
        # Response: 200
        desc 'Get all the terms of service offered by the server.'
        get do
          # TODO: implement
          status 200
        end

        # POST /terms
        # Auth: yes | Rate-limited: no
        # Response: 200
        desc 'Accept terms of service.'
        params do
          requires :user_accepts, type: Array[String], desc: 'The URLs the user is accepting'
        end
        post do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
