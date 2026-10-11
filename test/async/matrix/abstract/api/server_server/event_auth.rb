# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for what authorises an event, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::EventAuth}.
          module EventAuth
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

            # v1.1 asked what authorises an event.
            module V1_1
              def self.included(base)
                base.it "can getEventAuth" do
                  expect(server.event_auth.get_event_auth(room.id, event.event_id).auth_chain).not.to be(:empty?)
                end

                # Every chain reaches the creation of the room, which is what authorises the rest.
                base.it "reaches back to the creation of the room" do
                  expect(server.event_auth.get_event_auth(room.id, event.event_id).types).to be(:include?, "m.room.create")
                end

                base.it "says who is allowed to send it" do
                  expect(server.event_auth.get_event_auth(room.id, event.event_id).types).to be(:include?, "m.room.power_levels")
                end

                base.it "refuses an event which does not exist" do
                  expect do
                    server.event_auth.get_event_auth(room.id, "$nothing-at-all").auth_chain
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("event auth cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if EventAuth.const_defined?(name, false)
                  include EventAuth.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
