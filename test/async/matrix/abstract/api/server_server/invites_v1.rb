# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the first version of the invite, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::InvitesV1}.
          module InvitesV1
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

            # v1.1 invited a user, without the room version.
            module V1_1
              def self.included(base)
                base.let(:inviter){client.get_token_owner.user_id}

                # The first version carries no room version, so a server can only read the event in a room whose version it can assume: 1 or 2. The rig makes rooms at the version the homeserver defaults to, which has been well past that for years, so the invite is refused - and the case says so rather than pretending otherwise.
                base.it "can sendInviteV1" do
                  invited = room
                  version = room_version_of(invited)

                  event = {
                    "room_id" => invited.id,
                    "type" => "m.room.member",
                    "sender" => inviter,
                    "state_key" => outsider,
                    "content" => {"membership" => "invite"},
                    "origin_server_ts" => (Time.now.to_f * 1000).to_i,
                    "depth" => 1,
                    "prev_events" => [],
                    "auth_events" => [],
                  }

                  signed = signed_event(event, version)

                  expect do
                    server.invites_v1.send_invite_v1(invited.id, event_id_of(signed, version), signed).event
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "refuses an event which is not an invite at all" do
                  expect do
                    server.invites_v1.send_invite_v1(room.id, "$nothing-at-all", {}).event
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("invites v1 cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if InvitesV1.const_defined?(name, false)
                  include InvitesV1.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
