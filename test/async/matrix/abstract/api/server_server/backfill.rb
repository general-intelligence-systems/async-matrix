# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the events before the ones we have, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::Backfill}.
          module Backfill
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

            # v1.1 asked for the events before the ones we have.
            module V1_1
              def self.included(base)
                base.it "can backfillRoom" do
                  expect(server.backfill.backfill_room(room.id, [event.event_id]).types).to be(:include?, "m.room.message")
                end

                # The limit is what stops a server sending the whole history of a room.
                base.it "sends no more events than were asked for" do
                  expect(server.backfill.backfill_room(room.id, [event.event_id], limit: 1).pdus.size).to be <= 1
                end

                base.it "can getMissingPreviousEvents" do
                  sent = event

                  missing = server.backfill.get_missing_previous_events(room.id, [], [sent.event_id], limit: 10)

                  expect(missing.events).to be_a(Array)
                end

                # Nothing is missing between an event and itself.
                base.it "finds nothing missing where both ends are the same event" do
                  sent = event

                  missing = server.backfill.get_missing_previous_events(room.id, [sent.event_id], [sent.event_id])

                  expect(missing).to be(:empty?)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("backfill cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Backfill.const_defined?(name, false)
                  include Backfill.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
