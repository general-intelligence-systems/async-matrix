# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the keys a notary server holds, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::KeysQuery}.
          module KeysQuery
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

            # v1.1 asked a notary server for another's keys.
            module V1_1
              def self.included(base)
                # A notary vouches for servers it has fetched keys from, and the rig federates with nobody, so it vouches for none. The cases prove the request is the one the specification asked for.
                base.it "can perspectivesKeyQuery" do
                  expect(unauthenticated.keys_query.perspectives_key_query("elsewhere.test").server_keys).to be_a(Array)
                end

                base.it "asks for keys which are good for long enough" do
                  queried = unauthenticated.keys_query.perspectives_key_query("elsewhere.test", minimum_valid_until_ts: 1)

                  expect(queried).to be(:empty?)
                end

                base.it "can bulkPerspectivesKeyQuery" do
                  queried = unauthenticated.keys_query.bulk_perspectives_key_query({"elsewhere.test" => {}})

                  expect(queried.server_keys).to be_a(Array)
                end

                base.it "vouches for no server it has never spoken to" do
                  expect(unauthenticated.keys_query.bulk_perspectives_key_query({"elsewhere.test" => {}}).keys_of("elsewhere.test")).to be_nil
                end

                # A notary is asked before there is anything to sign with, so the request carries no signature.
                base.it "is asked without a signature" do
                  expect(unauthenticated.keys_query.perspectives_key_query("elsewhere.test")).to be(:empty?)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("notary keys cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if KeysQuery.const_defined?(name, false)
                  include KeysQuery.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
