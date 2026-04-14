# frozen_string_literal: true

# /_matrix/identity/v2/validate/msisdn/*
module MatrixApi
  module Identity
    module V2
      module Validate
        class Msisdn < Base
          # POST /validate/msisdn/requestToken
          # Auth: yes | Rate-limited: no
          # Response: 200, 400, 403
          desc 'Create a session for validating a phone number.' do
            failure [
              [400, 'Invalid address or send error (M_INVALID_ADDRESS, M_SEND_ERROR, M_DESTINATION_REJECTED)'],
              [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
            ]
          end
          params do
            requires :client_secret, type: String, desc: 'Unique client-generated string'
            requires :country, type: String, desc: 'ISO-3166-1 alpha-2 country code'
            requires :phone_number, type: String, desc: 'The phone number to validate'
            requires :send_attempt, type: Integer, desc: 'Increment to trigger a new SMS'
            optional :next_link, type: String, desc: 'URL to redirect to after validation'
          end
          post :requestToken do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /validate/msisdn/submitToken
          # Auth: yes | Rate-limited: no
          # Response: 200, 3XX, 403, 4XX
          desc 'Validate phone number ownership (GET - human-readable).' do
            failure [
              [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
            ]
          end
          params do
            requires :client_secret, type: String, desc: 'The client secret from requestToken'
            requires :sid, type: String, desc: 'The session ID from requestToken'
            requires :token, type: String, desc: 'The token sent to the user'
          end
          get :submitToken do
            authenticate!
            # TODO: implement
            status 200
          end

          # POST /validate/msisdn/submitToken
          # Auth: yes | Rate-limited: no
          # Response: 200, 400, 403
          desc 'Validate phone number ownership (POST).' do
            failure [
              [400, 'Validation error (M_TOKEN_INCORRECT, M_INVALID_PARAM, M_SESSION_EXPIRED)'],
              [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
            ]
          end
          params do
            requires :client_secret, type: String, desc: 'The client secret from requestToken'
            requires :sid, type: String, desc: 'The session ID from requestToken'
            requires :token, type: String, desc: 'The token sent to the user'
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
