# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the registration operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::Registration}.
          module Registration
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

            # v1.15 moved the password and deactivation operations out.
            module V1_15
              def self.included(base)
                # The methods are still here, and say where the operations went.
                base.it "says the password operations moved" do
                  error = nil

                  begin
                    client.registration.change_password("another-password")
                  rescue Async::Matrix::RemovedOperationError => error
                  end

                  expect(error.version).to be == "v1.15"
                  expect(error.to).to be == "PasswordManagement"
                  expect(error.replacement).to be == :change_password
                end

                base.it "says the deactivation moved" do
                  error = nil

                  begin
                    client.registration.deactivate_account
                  rescue Async::Matrix::RemovedOperationError => error
                  end

                  expect(error.version).to be == "v1.15"
                  expect(error.replacement).to be == :deactivate_account
                  expect(error.to).to be == "AccountDeactivation"
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

            # v1.10 added erase to deactivateAccount, and the case moved out again in v1.15.
            module V1_10
              WITHDRAWN_IN = "v1.15"

              def self.included(base)
                base.let(:auth){{type: "m.login.password", identifier: {type: "m.id.user", user: self.user_id}, password: Async::Matrix::TEST_PASSWORD}}

                # The user is this case's own, so there is nothing to lose by deactivating it.
                base.it "can deactivateAccount with erase" do
                  expect(client.registration.deactivate_account(auth: auth, erase: true)).to be(:unbound?)
                end
              end
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

            # v1.1 registered the password and deactivation operations here.
            module V1_1
              # The operations these cases exercise moved out in v1.15, and so did the cases.
              WITHDRAWN_IN = "v1.15"

              def self.included(base)
                # The rig accepts any password, so one round of user interactive authentication is enough.
                base.let(:auth){{type: "m.login.password", identifier: {type: "m.id.user", user: self.user_id}, password: Async::Matrix::TEST_PASSWORD}}

                base.it "can changePassword" do
                  expect(client.registration.change_password("another-password", auth: auth).value).to be == {}
                end

                # Without the authentication the homeserver asks for it, which is a refusal the case can read.
                base.it "is refused without user interactive authentication" do
                  error = nil

                  begin
                    client.registration.change_password("another-password")
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.status).to be == 401
                end

                # Mail is off in the rig, so the homeserver will not send a reset token.
                base.it "can requestTokenToResetPasswordEmail" do
                  expect do
                    client.registration.request_token_to_reset_password_email("a-secret", "nobody@example.com")
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "can requestTokenToResetPasswordMSISDN" do
                  expect do
                    client.registration.request_token_to_reset_password_msisdn("a-secret", "GB", "7700900000")
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                # The user is this case's own, so there is nothing to lose by deactivating it.
                base.it "can deactivateAccount" do
                  expect(client.registration.deactivate_account(auth: auth)).to be(:unbound?)
                end
              end
            end
            # The cases required at the version under test.
            #
            # A layer whose operations a later version moved away names that version, and is left out once the version under test has reached it: the cases follow the operations.
            CASES = Sus::Shared("registration cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Registration.const_defined?(name, false)
                  layer = Registration.const_get(name, false)

                  if layer.const_defined?(:WITHDRAWN_IN, false) and Async::Matrix::Versions.up_to(Async::Matrix::TEST_VERSION).include?(layer::WITHDRAWN_IN)
                    next
                  end

                  include layer
                end
              end
            end
          end
        end
      end
    end
  end
end
