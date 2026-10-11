# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for sending a signed join back, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::JoinsV2}.
          module JoinsV2
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

            # v1.6 let the membership be left out.
            module V1_6
              def self.included(base)
                base.it "leaves the memberships out when asked" do
                  joined = room
                  version = room_version_of(joined)

                  template = server.joins_v1.make_join(joined.id, outsider, versions: [version])
                  signed = signed_event(template.event, version)

                  result = server.joins_v2.send_join_v2(joined.id, event_id_of(signed, version), signed, omit_members: true)

                  expect(result.servers_in_room).to be(:include?, server_name)
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

            # v1.1 sent the join without the status wrapper.
            module V1_1
              def self.included(base)
                # The whole flow: ask for a template, sign it, and send it back. The suite signs as the server which owns the room, which is the only server there is.
                base.it "can sendJoinV2" do
                  joined = room
                  version = room_version_of(joined)

                  template = server.joins_v1.make_join(joined.id, outsider, versions: [version])
                  signed = signed_event(template.event, version)

                  result = server.joins_v2.send_join_v2(joined.id, event_id_of(signed, version), signed)

                  expect(result.types).to be(:include?, "m.room.create")
                end

                base.it "answers with the join as the room now has it" do
                  joined = room
                  version = room_version_of(joined)

                  template = server.joins_v1.make_join(joined.id, outsider, versions: [version])
                  signed = signed_event(template.event, version)

                  result = server.joins_v2.send_join_v2(joined.id, event_id_of(signed, version), signed)

                  expect(result.event[:type]).to be == "m.room.member"
                end

                # An event which is not signed is refused, which is the whole point of signing it.
                base.it "refuses an event which was not signed" do
                  joined = room
                  version = room_version_of(joined)

                  template = server.joins_v1.make_join(joined.id, outsider, versions: [version])

                  expect do
                    server.joins_v2.send_join_v2(joined.id, "$not-signed", template.event).state
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("joins v2 cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if JoinsV2.const_defined?(name, false)
                  include JoinsV2.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
