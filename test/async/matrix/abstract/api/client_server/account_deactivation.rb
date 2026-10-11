# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the deactivation, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::AccountDeactivation}.
          module AccountDeactivation
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

            # v1.15 took the deactivation from the registration.
            module V1_15
              def self.included(base)
                # The rig accepts any password, so one round of user interactive authentication is enough.
                base.let(:auth){{type: "m.login.password", identifier: {type: "m.id.user", user: self.user_id}, password: Async::Matrix::TEST_PASSWORD}}

                # The user is this case's own, so there is nothing to lose by deactivating it.
                base.it "can deactivateAccount" do
                  expect(client.account_deactivation.deactivate_account(auth: auth, erase: true)).to be(:unbound?)
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
            CASES = Sus::Shared("deactivation cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if AccountDeactivation.const_defined?(name, false)
                  include AccountDeactivation.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
