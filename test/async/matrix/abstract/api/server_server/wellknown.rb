# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for where a server is to be reached, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::Wellknown}.
          module Wellknown
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

            # v1.1 published where a server is to be reached.
            module V1_1
              def self.included(base)
                # The rig turns `serve_server_wellknown` on, so the homeserver answers for itself.
                base.it "can getWellKnown" do
                  expect(unauthenticated.wellknown.get_well_known.server).not.to be_nil
                end

                base.it "says the server delegates somewhere" do
                  expect(unauthenticated.wellknown.get_well_known).to be(:delegated?)
                end

                # The document is not under `/_matrix`, and is not signed: it is read before there is a server to verify against.
                base.it "is read without a signature" do
                  expect(unauthenticated.wellknown.get_well_known.resource.path).to be == "/.well-known/matrix/server"
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("wellknown cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Wellknown.const_defined?(name, false)
                  include Wellknown.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
