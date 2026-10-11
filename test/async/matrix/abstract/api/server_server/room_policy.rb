# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the policy server a room may name, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::RoomPolicy}.
          module RoomPolicy
            # No changes in v1.19.
            module V1_19
            end

            # v1.18 added the policy server a room may name.
            module V1_18
              def self.included(base)
                # A policy server is a service of its own, and the rig runs none: the homeserver does not answer the path. The case asserts the refusal, as the client-server cases do for the document a policy server would publish.
                base.it "can askPolicyServerToSign" do
                  event = {type: "m.room.message", room_id: room.id, sender: user_id, content: {msgtype: "m.text", body: "for signing"}}

                  expect do
                    server.room_policy.ask_policy_server_to_sign(event).signatures
                  end.to raise_exception(Async::Matrix::RequestError)
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

            # No changes in v1.1.
            module V1_1
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("room policy cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if RoomPolicy.const_defined?(name, false)
                  include RoomPolicy.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
