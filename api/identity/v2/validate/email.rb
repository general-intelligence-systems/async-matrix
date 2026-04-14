# frozen_string_literal: true

# /_matrix/identity/v2/validate/email/*
module MatrixApi
  module Identity
    module V2
      module Validate
        class Email < Base
          # POST /validate/email/requestToken
          # Auth: yes | Rate-limited: no
          # Response: 200, 400, 403
          desc 'Create a session for validating an email address.' do
            failure [
              [400, 'Invalid email or send error (M_INVALID_EMAIL, M_EMAIL_SEND_ERROR)'],
              [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
            ]
          end
          params do
            requires :client_secret, type: String, desc: 'Unique client-generated string'
            requires :email, type: String, desc: 'The email address to validate'
            requires :send_attempt, type: Integer, desc: 'Increment to trigger a new email'
            optional :next_link, type: String, desc: 'URL to redirect to after validation'
          end
          post :requestToken do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /validate/email/submitToken
          # Auth: yes | Rate-limited: no
          # Response: 200, 3XX, 403, 4XX
          desc 'Validate email ownership (GET - human-readable).' do
            failure [
              [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
            ]
          end
          params do
            requires :client_secret, type: String, desc: 'The client secret from requestToken'
            requires :sid, type: String, desc: 'The session ID from requestToken'
            requires :token, type: String, desc: 'The token emailed to the user'
          end
          get :submitToken do
            authenticate!
            # TODO: implement
            status 200
          end

          # POST /validate/email/submitToken
          # Auth: yes | Rate-limited: no
          # Response: 200, 400, 403
          desc 'Validate email ownership (POST).' do
            failure [
              [400, 'Validation error (M_TOKEN_INCORRECT, M_INVALID_PARAM, M_SESSION_EXPIRED)'],
              [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
            ]
          end
          params do
            requires :client_secret, type: String, desc: 'The client secret from requestToken'
            requires :sid, type: String, desc: 'The session ID from requestToken'
            requires :token, type: String, desc: 'The token emailed to the user'
          end
          post :submitToken do
            authenticate!
            # TODO: implement
            status 200
          end
        end
      end
    end
  end
end
