# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the events of a room and the state around them, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::Events}.
          module Events
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

            # v1.6 found the event nearest a time.
            module V1_6
              def self.included(base)
                # The message is the last thing which happened in the room, so searching backwards from now finds it.
                base.it "can getEventByTimestamp" do
                  sent = event

                  found = server.events.get_event_by_timestamp(room.id, self.now, "b")

                  expect(found.event_id).to be == sent.event_id
                end

                base.it "answers when the event it found was sent" do
                  event

                  found = server.events.get_event_by_timestamp(room.id, self.now, "b")

                  expect(found.origin_server_ts).to be > 0
                end

                # Nothing was sent after the message, so there is no event forwards of a later time.
                base.it "refuses a direction in which there is nothing" do
                  event

                  expect do
                    server.events.get_event_by_timestamp(room.id, self.now + 60_000, "f").event_id
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                # The time a search runs from, which the specification counts in milliseconds.
                base.define_method(:now) do
                  (Time.now.to_f * 1000).to_i
                end
              end
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

            # v1.1 read an event and the state around it.
            module V1_1
              def self.included(base)
                # The suite signs as the server which owns the room, which is the only server there is: a server which is not in a room is refused.
                base.it "can getEvent" do
                  sent = event

                  expect(server.events.get_event(sent.event_id).first[:content][:body]).to be == "over federation"
                end

                base.it "answers one event in the transaction" do
                  expect(server.events.get_event(event.event_id).pdus.size).to be == 1
                end

                base.it "can getRoomState" do
                  state = server.events.get_room_state(room.id, event.event_id)

                  expect(state.pdus).not.to be(:empty?)
                  expect(state.auth_chain).not.to be(:empty?)
                end

                base.it "reads the creation of the room in its state" do
                  types = server.events.get_room_state(room.id, event.event_id).pdus.map{|pdu| pdu[:type]}

                  expect(types).to be(:include?, "m.room.create")
                end

                base.it "can getRoomStateIds" do
                  state = server.events.get_room_state_ids(room.id, event.event_id)

                  expect(state.pdu_ids).not.to be(:empty?)
                  expect(state.auth_chain_ids).not.to be(:empty?)
                end

                # The two are the same state, said two ways, so they are the same size.
                base.it "names as many state events as it sends" do
                  ids = server.events.get_room_state_ids(room.id, event.event_id)
                  events = server.events.get_room_state(room.id, event.event_id)

                  expect(ids.pdu_ids.size).to be == events.pdus.size
                end

                base.it "refuses an event which does not exist" do
                  expect do
                    server.events.get_event("$nothing-at-all").pdus
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("events cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Events.const_defined?(name, false)
                  include Events.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
