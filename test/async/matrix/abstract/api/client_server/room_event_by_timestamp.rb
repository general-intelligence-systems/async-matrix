# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the timestamp lookup, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::RoomEventByTimestamp}.
          module RoomEventByTimestamp
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

            # v1.6 added the timestamp lookup.
            module V1_6
              # A moment after the message the cases send, since the search finds the event nearest the moment it is given and `Time.now` floors to the second it is already in.
              AFTER_THE_MESSAGE = ->{(Time.now.to_f * 1000).to_i + 1000}

              def self.included(base)
                base.it "can getEventByTimestamp" do
                  sent = room.send_message("m.room.message", {msgtype: "m.text", body: "at a time"})

                  found = client.room_event_by_timestamp.get_event_by_timestamp(room.id, AFTER_THE_MESSAGE.call, dir: "b")

                  expect(found.event_id).to be == sent.event_id
                end

                base.it "reports when the event it found was sent" do
                  room.send_message("m.room.message", {msgtype: "m.text", body: "at a time"})

                  found = client.room_event_by_timestamp.get_event_by_timestamp(room.id, AFTER_THE_MESSAGE.call, dir: "b")

                  expect(found.origin_server_ts).to be > 0
                end

                # The room was created now, so nothing precedes it and the homeserver has nothing to answer with.
                base.it "fails where no event lies that way" do
                  error = nil

                  begin
                    client.room_event_by_timestamp.get_event_by_timestamp(room.id, 1, dir: "b")
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error).to be_a(Async::Matrix::RequestError)
                  expect(error.status).to be == 404
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

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("timestamp lookup cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if RoomEventByTimestamp.const_defined?(name, false)
                  include RoomEventByTimestamp.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
