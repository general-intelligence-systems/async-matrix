# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the registration tokens, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::RegistrationTokens}.
          module RegistrationTokens
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

            # No changes in v1.15.
            module V1_15
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

            # v1.2 added asking whether a token is still good.
            module V1_2
              def self.included(base)
                # The rig sets `enable_registration: false`, so the homeserver will not discuss tokens at all. The case asserts the refusal it gives.
                base.it "can registrationTokenValidity" do
                  error = nil

                  begin
                    unauthenticated.registration_tokens.registration_token_validity("not-a-token")
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.errcode).to be == "M_FORBIDDEN"
                end
              end
            end

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("registration token cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if RegistrationTokens.const_defined?(name, false)
                  include RegistrationTokens.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
