# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the read markers operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::ReadMarkers}.
          module ReadMarkers
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

            # v1.4 added the private receipt.
            module V1_4
              def self.included(base)
                base.it "sends a private receipt, which the other members do not see" do
                  expect(client.read_markers.set_read_marker(room.id, fully_read: sent.event_id, read_private: sent.event_id).value).to be == {}
                end

                # The marker was required until v1.4, so a receipt alone is what this version added.
                base.it "sets a receipt without the marker" do
                  expect(client.read_markers.set_read_marker(room.id, read: sent.event_id).value).to be == {}
                end
              end
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
            CASES = Sus::Shared("read markers cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if ReadMarkers.const_defined?(name, false)
                  include ReadMarkers.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
