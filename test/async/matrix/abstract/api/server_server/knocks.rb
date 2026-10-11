# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for knocking on a room, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::Knocks}.
          module Knocks
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

            # v1.1 knocked on a room through another server.
            module V1_1
              def self.included(base)
                # Knocking is refused unless the room asks for it, so the room is made with that rule.
                base.let(:knockable) do
                  client.create_room(name: "Knockable", initial_state: [{type: "m.room.join_rules", content: {join_rule: "knock"}}])
                end

                base.it "can makeKnock" do
                  template = server.knocks.make_knock(knockable.id, outsider, versions: [room_version_of(knockable)])

                  expect(template.membership).to be == "knock"
                end

                base.it "can sendKnock" do
                  asked = knockable
                  version = room_version_of(asked)

                  template = server.knocks.make_knock(asked.id, outsider, versions: [version])
                  signed = signed_event(template.event, version)

                  result = server.knocks.send_knock(asked.id, event_id_of(signed, version), signed)

                  expect(result.types).to be(:include?, "m.room.join_rules")
                end

                # A room which does not ask to be knocked on refuses, whoever is asking.
                base.it "refuses a knock on a room which does not allow it" do
                  expect do
                    server.knocks.make_knock(room.id, outsider, versions: [room_version_of(room)]).event
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "refuses a knock which was not signed" do
                  asked = knockable
                  version = room_version_of(asked)

                  template = server.knocks.make_knock(asked.id, outsider, versions: [version])

                  expect do
                    server.knocks.send_knock(asked.id, "$not-signed", template.event).knock_room_state
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("knocks cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Knocks.const_defined?(name, false)
                  include Knocks.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
