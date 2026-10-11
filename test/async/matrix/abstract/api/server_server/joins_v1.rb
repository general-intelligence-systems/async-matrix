# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for joining a room through another server, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::JoinsV1}.
          module JoinsV1
            # No changes in v1.19.
            module V1_19
            end

            # v1.18 withdrew the first version of the send.
            module V1_18
              def self.included(base)
                # The method the send was reached by is still here, and says what became of it.
                base.it "says the send was replaced" do
                  error = nil

                  begin
                    server.joins_v1.send_join_v1(room.id, "$nothing", {})
                  rescue Async::Matrix::RemovedOperationError => error
                  end

                  expect(error.version).to be == "v1.18"
                  expect(error.replacement).to be == :send_join_v2
                end
              end
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

            # v1.1 joined a room through another server.
            module V1_1
              def self.included(base)
                base.it "can makeJoin" do
                  template = server.joins_v1.make_join(room.id, outsider, versions: [room_version_of(room)])

                  expect(template.room_version).not.to be_nil
                  expect(template.membership).to be == "join"
                end

                # A server which does not understand the room's version is refused, which is what the list is for.
                base.it "refuses a room version the asking server does not know" do
                  expect do
                    server.joins_v1.make_join(room.id, outsider, versions: ["not-a-version"]).event
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "refuses to build a join for a user of another server" do
                  expect do
                    server.joins_v1.make_join(room.id, "@someone:elsewhere.test", versions: [room_version_of(room)]).event
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("make join cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if JoinsV1.const_defined?(name, false)
                  include JoinsV1.const_get(name, false)
                end
              end
            end
          end

          # Cases for the send v1.18 withdrew.
          module SendJoinV1
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

            # v1.1 sent the join with a status wrapper.
            module V1_1
              # The operation these cases send with was withdrawn in v1.18, and so were they.
              WITHDRAWN_IN = "v1.18"

              def self.included(base)
                base.it "can sendJoinV1" do
                  joined = room
                  version = room_version_of(joined)

                  template = server.joins_v1.make_join(joined.id, outsider, versions: [version])
                  signed = signed_event(template.event, version)

                  result = server.joins_v1.send_join_v1(joined.id, event_id_of(signed, version), signed)

                  expect(result.state).not.to be(:empty?)
                end
              end
            end

            # The cases required at the version under test.
            #
            # A layer whose operations a later version withdrew names that version, and is left out once the version under test has reached it: the cases follow the operations.
            CASES = Sus::Shared("send join v1 cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if SendJoinV1.const_defined?(name, false)
                  layer = SendJoinV1.const_get(name, false)

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
