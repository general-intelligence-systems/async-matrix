# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the password operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::PasswordManagement}.
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
              def self.included(base)
                # The rig accepts any password, so one round of user interactive authentication is enough.
                base.let(:auth){{type: "m.login.password", identifier: {type: "m.id.user", user: self.user_id}, password: Async::Matrix::TEST_PASSWORD}}

                base.it "can changePassword" do
                  expect(client.password_management.change_password("another-password", auth: auth).value).to be == {}
                end

                # Without the authentication the homeserver asks for it, which is a refusal the case can read.
                base.it "is refused without user interactive authentication" do
                  error = nil

                  begin
                    client.password_management.change_password("another-password")
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.status).to be == 401
                end

                # Mail is off in the rig, so the homeserver will not send a reset token.
                base.it "can requestTokenToResetPasswordEmail" do
                  expect do
                    client.password_management.request_token_to_reset_password_email("a-secret", "nobody@example.com")
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "can requestTokenToResetPasswordMSISDN" do
                  expect do
                    client.password_management.request_token_to_reset_password_msisdn("a-secret", "GB", "7700900000")
                  end.to raise_exception(Async::Matrix::RequestError)
                end
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
            # The cases required at the version under test.
            CASES = Sus::Shared("password cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if PasswordManagement.const_defined?(name, false)
                  include PasswordManagement.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
