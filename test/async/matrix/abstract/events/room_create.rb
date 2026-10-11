# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"

module Async
  module Matrix
    module Testing
      module Abstract
        module Events
          module RoomCreate
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # v1.16 added the additional creators.
            module V1_16
              def self.included(base)
                base.it "reads the additional creators v1.16 added" do
                  create = Async::Matrix::Events[Async::Matrix::TEST_VERSION]::RoomCreate.new({creator: "@alice:localhost", additional_creators: ["@bob:localhost"]})

                  expect(create.additional_creators).to be == ["@bob:localhost"]
                end
              end
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

            # v1.2 added the room type.
            module V1_2
              def self.included(base)
                base.it "reads the room type v1.2 added" do
                  create = Async::Matrix::Events[Async::Matrix::TEST_VERSION]::RoomCreate.new({creator: "@alice:localhost", type: "m.space"})

                  expect(create.room_type).to be == "m.space"
                end
              end
            end

            # No changes in v1.1.
            module V1_1
            end

            CASES = Sus::Shared("room create cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if RoomCreate.const_defined?(name, false)
                  include RoomCreate.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
