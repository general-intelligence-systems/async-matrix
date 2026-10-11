# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the administrative contact operations, layered by version.
#
# The rig has no identity server and no mail, so the operations which need one refuse. What the refusal is called is what changes.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::AdministrativeContact}.
          module AdministrativeContact
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

            # v1.12 runs Synapse 1.135.0, which names the refusal.
            module V1_12
              def self.included(base)
                # Synapse 1.135.0 gave the refusal an error code of its own, where it was M_UNKNOWN before.
                base.let(:unsupported_medium_errcode){"M_THREEPID_MEDIUM_NOT_SUPPORTED"}
              end
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

            # v1.1 runs Synapse 1.54.0, which refuses as M_UNKNOWN.
            module V1_1
              def self.included(base)
                # Mail is off in the rig and there is no identity server, so the homeserver will not start a validation.
                base.it "can requestTokenTo3PIDEmail" do
                  error = nil

                  begin
                    contact.request_token_to_3pid_email("a-secret", "nobody@example.com")
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.errcode).to be == self.unsupported_medium_errcode
                end

                base.it "can requestTokenTo3PIDMSISDN" do
                  error = nil

                  begin
                    contact.request_token_to_3pid_msisdn("a-secret", "GB", "7700900000")
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.errcode).to be == self.unsupported_medium_errcode
                end

                # What the refusal is called, which a later layer changes.
                base.let(:unsupported_medium_errcode){"M_UNKNOWN"}
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("administrative contact cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if AdministrativeContact.const_defined?(name, false)
                  include AdministrativeContact.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
