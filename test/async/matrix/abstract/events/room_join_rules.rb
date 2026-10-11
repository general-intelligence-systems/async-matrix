# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"

module Async
  module Matrix
    module Testing
      module Abstract
        module Events
          module RoomJoinRules
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

            # v1.2 added the allow rules a restricted join reads.
            module V1_2
              def self.included(base)
                base.it "reads the allow rules v1.2 added" do
                  join_rules = Async::Matrix::Events[Async::Matrix::TEST_VERSION]::RoomJoinRules.new({join_rule: "restricted", allow: [{type: "m.room_membership", room_id: "!room:localhost"}]})

                  expect(join_rules.allow).to be == [{type: "m.room_membership", room_id: "!room:localhost"}]
                end
              end
            end

            # No changes in v1.1.
            module V1_1
            end

            CASES = Sus::Shared("room join rules cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if RoomJoinRules.const_defined?(name, false)
                  include RoomJoinRules.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
