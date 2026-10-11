# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the versions operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::SupportedVersions}.
          module SupportedVersions
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

            # v1.1 is named by the homeserver which implements it.
            module V1_1
              # No Synapse advertises v1.18 or v1.19 yet - develop reaches v1.17 - so from there the answer cannot name the version under test, and these cases stop. Remove this once one does.
              WITHDRAWN_IN = "v1.18"

              def self.included(base)
                base.it "names the version under test" do
                  expect(client.supported_versions.get_versions.versions).to be(:include?, Async::Matrix::TEST_VERSION)
                end

                base.it "says which versions it implements" do
                  expect(client.supported_versions.get_versions).to be(:supports?, Async::Matrix::TEST_VERSION)
                end

                # The client offers the short way to ask, which is the same request.
                base.it "is what the client asks for its versions" do
                  expect(client.versions.versions).to be(:include?, Async::Matrix::TEST_VERSION)
                end
              end
            end

            # The cases required at the version under test.
            #
            # A layer which names the version it stopped holding at is left out from there, so a version no homeserver advertises asks nothing of the answer.
            CASES = Sus::Shared("versions cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if SupportedVersions.const_defined?(name, false)
                  layer = SupportedVersions.const_get(name, false)

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
