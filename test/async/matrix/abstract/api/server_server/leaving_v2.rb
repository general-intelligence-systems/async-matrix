# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for sending a signed leave back, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::LeavingV2}.
          module LeavingV2
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

            # v1.1 sent the leave without the status wrapper.
            module V1_1
              def self.included(base)
                base.let(:member){client.get_token_owner.user_id}

                # The whole flow: ask for a template, sign it, and send it back.
                base.it "can sendLeaveV2" do
                  left = room
                  version = room_version_of(left)

                  template = server.leaving_v1.make_leave(left.id, member)
                  signed = signed_event(template.event, version)

                  result = server.leaving_v2.send_leave_v2(left.id, event_id_of(signed, version), signed)

                  expect(result.value).to be == {}
                end

                # The leave is a membership change, so the room says the user has gone.
                #
                # Somebody else stays behind: once the last member leaves, the server is no longer in the room and will not be asked about it.
                base.it "takes the user out of the room" do
                  left = room
                  version = room_version_of(left)

                  newcomer = self.account("fed-#{SecureRandom.hex(6)}")
                  newcomer.join_room(left.id)
                  leaver = newcomer.get_token_owner.user_id

                  template = server.leaving_v1.make_leave(left.id, leaver)
                  signed = signed_event(template.event, version)

                  server.leaving_v2.send_leave_v2(left.id, event_id_of(signed, version), signed)

                  # Read through the client, because the state at an event is the state before it.
                  membership = left.get_room_state_with_key("m.room.member", leaver)

                  expect(membership.value[:membership]).to be == "leave"
                end

                base.it "refuses an event which was not signed" do
                  left = room

                  template = server.leaving_v1.make_leave(left.id, member)

                  expect do
                    server.leaving_v2.send_leave_v2(left.id, "$not-signed", template.event).value
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("leaving v2 cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if LeavingV2.const_defined?(name, false)
                  include LeavingV2.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
