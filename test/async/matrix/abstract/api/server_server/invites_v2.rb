# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for inviting a user through their own server, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::InvitesV2}.
          module InvitesV2
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

            # v1.1 invited a user, saying the room version.
            module V1_1
              def self.included(base)
                base.let(:inviter){client.get_token_owner.user_id}

                # An invite is not built by the invited server, so there is no template to ask for: the inviting server builds the event and signs it.
                base.define_method(:invite_event) do |room_id, invitee|
                  {
                    "room_id" => room_id,
                    "type" => "m.room.member",
                    "sender" => inviter,
                    "state_key" => invitee,
                    "content" => {"membership" => "invite"},
                    "origin_server_ts" => (Time.now.to_f * 1000).to_i,
                    "depth" => 1,
                    "prev_events" => [],
                    "auth_events" => [],
                  }
                end

                base.it "can sendInviteV2" do
                  invited = room
                  version = room_version_of(invited)

                  signed = signed_event(invite_event(invited.id, outsider), version)

                  result = server.invites_v2.send_invite_v2(invited.id, event_id_of(signed, version), signed, room_version: version)

                  expect(result.event[:type]).to be == "m.room.member"
                end

                # The invited server signs the event, which is how it says it took it.
                base.it "answers with the event the invited server signed" do
                  invited = room
                  version = room_version_of(invited)

                  signed = signed_event(invite_event(invited.id, outsider), version)

                  result = server.invites_v2.send_invite_v2(invited.id, event_id_of(signed, version), signed, room_version: version)

                  expect(result).to be(:signed_by?, server_name)
                end

                base.it "carries enough state to show the room" do
                  invited = room
                  version = room_version_of(invited)

                  signed = signed_event(invite_event(invited.id, outsider), version)
                  state = [{type: "m.room.name", state_key: "", sender: inviter, content: {name: "Invited"}}]

                  result = server.invites_v2.send_invite_v2(invited.id, event_id_of(signed, version), signed, room_version: version, invite_room_state: state)

                  expect(result.event).not.to be(:empty?)
                end

                base.it "refuses a room version it does not know" do
                  invited = room
                  version = room_version_of(invited)

                  signed = signed_event(invite_event(invited.id, outsider), version)

                  expect do
                    server.invites_v2.send_invite_v2(invited.id, event_id_of(signed, version), signed, room_version: "not-a-version").event
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("invites v2 cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if InvitesV2.const_defined?(name, false)
                  include InvitesV2.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
