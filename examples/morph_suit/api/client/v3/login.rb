# frozen_string_literal: true

# /_matrix/client/v3/login
module MatrixApi
  module Client
    module V3
      class Login < Base
        # GET /login - Get supported login types
        # Auth: no | Rate-limited: yes
        # Response: 200, 429
        desc 'Get supported login types.' do
          detail 'Returns the list of supported login flows.'
          failure [[429, 'Rate limited (M_LIMIT_EXCEEDED)']]
        end
        get do
          rate_limit!
          # TODO: implement
          status 200
        end

        # POST /login - Authenticate the user
        # Auth: no | Rate-limited: yes
        # Response: 200, 400, 403, 429
        desc 'Authenticate the user.' do
          detail 'Authenticates the user and returns an access token.'
          failure [
            [400, 'Bad request (M_BAD_JSON, M_NOT_JSON)'],
            [403, 'Forbidden (M_FORBIDDEN, M_USER_DEACTIVATED)'],
            [429, 'Rate limited (M_LIMIT_EXCEEDED)']
          ]
        end
        params do
          requires :type, type: String, desc: 'Login type (e.g. m.login.password)'
          optional :identifier, type: Hash, desc: 'User identifier object'
          optional :password, type: String, desc: 'Password (for m.login.password)'
          optional :token, type: String, desc: 'Login token (for m.login.token)'
          optional :device_id, type: String, desc: 'Device ID to associate with session'
          optional :initial_device_display_name, type: String, desc: 'Display name for the device'
          optional :refresh_token, type: Boolean, desc: 'Request a refresh token'
        end
        post do
          rate_limit!
          # TODO: implement
          status 200
        end

        # GET /login/sso/redirect - SSO redirect
        # Auth: no | Rate-limited: no
        # Response: 302
        namespace :sso do
          desc 'Redirect to the SSO login page.' do
            detail 'Redirects the user to the SSO interface.'
          end
          params do
            requires :redirectUrl, type: String, desc: 'URL to redirect back to after SSO'
            optional :action, type: String, values: %w[login register], desc: 'Hint (added v1.18)'
          end
          get :redirect do
            # TODO: implement - should return 302 redirect
            status 302
          end

          # GET /login/sso/redirect/:idpId - SSO redirect to specific IdP
          # Auth: no | Rate-limited: no
          # Response: 302
          desc 'Redirect to a specific SSO identity provider.' do
            detail 'Redirects the user to the specific SSO IdP interface.'
          end
          params do
            requires :idpId, type: String, desc: 'The identity provider ID'
            requires :redirectUrl, type: String, desc: 'URL to redirect back to after SSO'
            optional :action, type: String, values: %w[login register], desc: 'Hint'
          end
          get 'redirect/:idpId' do
            # TODO: implement - should return 302 redirect
            status 302
          end
        end
      end
    end
  end
end
