# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the cross signing operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module CrossSigning
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

            # No changes in v1.2.
            module V1_2
            end

            # v1.1 is the oldest version, and carries both cases.
            module V1_1
              def self.included(base)
                base.it "can uploadCrossSigningSignatures" do
                  expect(client.cross_signing.upload_signatures({})).to be(:accepted?)
                end

                # The server checks the key before it asks for authentication, and we have nothing to sign it with.
                base.it "can uploadCrossSigningKeys" do
                  error = nil

                  begin
                    client.cross_signing.upload(master_key: {user_id: self.user_id, usage: ["master"], keys: {}})
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error).to be_a(Async::Matrix::RequestError)
                  expect(error.status).to be == 400
                  expect(error.errcode).to be == "M_INVALID_PARAM"
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("cross signing cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if CrossSigning.const_defined?(name, false)
                  include CrossSigning.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
