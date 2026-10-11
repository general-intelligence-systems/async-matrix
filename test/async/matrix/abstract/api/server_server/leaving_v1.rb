# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for leaving a room through another server, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::LeavingV1}.
          module LeavingV1
            # No changes in v1.19.
            module V1_19
            end

            # v1.18 withdrew the first version of the send.
            module V1_18
              def self.included(base)
                base.it "says the send was replaced" do
                  error = nil

                  begin
                    server.leaving_v1.send_leave_v1(room.id, "$nothing", {})
                  rescue Async::Matrix::RemovedOperationError => error
                  end

                  expect(error.version).to be == "v1.18"
                  expect(error.replacement).to be == :send_leave_v2
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

            # v1.1 left a room through another server.
            module V1_1
              def self.included(base)
                # The user who leaves is the one who made the room: there is nobody else in it.
                base.let(:member){client.get_token_owner.user_id}

                base.it "can makeLeave" do
                  template = server.leaving_v1.make_leave(room.id, member)

                  expect(template.room_version).not.to be_nil
                  expect(template.membership).to be == "leave"
                end

                base.it "refuses to build a leave for a user of another server" do
                  expect do
                    server.leaving_v1.make_leave(room.id, "@someone:elsewhere.test").event
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("make leave cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if LeavingV1.const_defined?(name, false)
                  include LeavingV1.const_get(name, false)
                end
              end
            end
          end

          # Cases for the send v1.18 withdrew.
          module SendLeaveV1
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

            # v1.1 sent the leave with a status wrapper.
            module V1_1
              # The operation these cases send with was withdrawn in v1.18, and so were they.
              WITHDRAWN_IN = "v1.18"

              def self.included(base)
                base.let(:member){client.get_token_owner.user_id}

                base.it "can sendLeaveV1" do
                  left = room
                  version = room_version_of(left)

                  template = server.leaving_v1.make_leave(left.id, member)
                  signed = signed_event(template.event, version)

                  result = server.leaving_v1.send_leave_v1(left.id, event_id_of(signed, version), signed)

                  expect(result.value).not.to be_nil
                end
              end
            end

            # The cases required at the version under test.
            #
            # A layer whose operations a later version withdrew names that version, and is left out once the version under test has reached it: the cases follow the operations.
            CASES = Sus::Shared("send leave v1 cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if SendLeaveV1.const_defined?(name, false)
                  layer = SendLeaveV1.const_get(name, false)

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
