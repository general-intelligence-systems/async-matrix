# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::PasswordManagement}.
        module PasswordManagement
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # No changes in v1.16.
          module V1_16
          end

          # v1.15 took the password operations from the registration.
          module V1_15
            # Change this user's password.
            #
            # @parameter new_password [String] the password to set.
            # @parameter logout_devices [Boolean | nil] whether to log the other devices out, which the homeserver does by default.
            # @parameter auth [Hash | nil] the user interactive authentication, without which the homeserver asks for it.
            # @returns [Representation] the empty response.
            def change_password(new_password, logout_devices: nil, auth: nil)
              payload = {new_password: new_password, logout_devices: logout_devices, auth: auth}.compact

              api::Representation.post(@resource.with(path: "#{V3}/account/password"), payload)
            end

            # Ask for a token to validate an email address with, so that a password can be reset through it.
            #
            # @parameter client_secret [String] a secret of the client's own, quoted back when the token is used.
            # @parameter email [String] the address to send it to.
            # @parameter send_attempt [Integer] the attempt, which the homeserver sends again only when it rises.
            # @parameter options [Hash] the rest the specification allows, e.g. `next_link:`.
            # @returns [ThreePidValidation] the session the validation runs in.
            def request_token_to_reset_password_email(client_secret, email, send_attempt: 1, **options)
              payload = {client_secret: client_secret, email: email, send_attempt: send_attempt, **options}

              api::ThreePidValidation.post(@resource.with(path: "#{V3}/account/password/email/requestToken"), payload)
            end

            # Ask for a token to validate a phone number with, so that a password can be reset through it.
            #
            # @parameter client_secret [String] a secret of the client's own, quoted back when the token is used.
            # @parameter country [String] the two letter country code the number belongs to.
            # @parameter phone_number [String] the number to send it to, as it is dialled in that country.
            # @parameter send_attempt [Integer] the attempt, which the homeserver sends again only when it rises.
            # @parameter options [Hash] the rest the specification allows, e.g. `next_link:`.
            # @returns [ThreePidValidation] the session the validation runs in.
            def request_token_to_reset_password_msisdn(client_secret, country, phone_number, send_attempt: 1, **options)
              payload = {client_secret: client_secret, country: country, phone_number: phone_number, send_attempt: send_attempt, **options}

              api::ThreePidValidation.post(@resource.with(path: "#{V3}/account/password/msisdn/requestToken"), payload)
            end
          end

          # No changes in v1.14.
          module V1_14
          end

          # No changes in v1.13.
          module V1_13
          end

          # No changes in v1.12.
          module V1_12
          end

          # No changes in v1.11.
          module V1_11
          end

          # No changes in v1.10.
          module V1_10
          end

          # No changes in v1.9.
          module V1_9
          end

          # No changes in v1.8.
          module V1_8
          end

          # No changes in v1.7.
          module V1_7
          end

          # No changes in v1.6.
          module V1_6
          end

          # No changes in v1.5.
          module V1_5
          end

          # No changes in v1.4.
          module V1_4
          end

          # No changes in v1.3.
          module V1_3
          end

          # No changes in v1.2.
          module V1_2
          end

          # No changes in v1.1.
          module V1_1
          end
        end
      end
    end
  end
end
