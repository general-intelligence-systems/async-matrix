# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"

module Async
  module Matrix
    module Testing
      module Abstract
        module Events
          module RoomRedaction
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

            # v1.8 moved redacts into the content.
            module V1_8
              def self.included(base)
                base.it "reads the redacts field v1.8 moved into the content" do
                  redaction = Async::Matrix::Events[Async::Matrix::TEST_VERSION]::RoomRedaction.new({redacts: "$event:localhost", reason: "spam"})

                  expect(redaction.redacts).to be == "$event:localhost"
                end
              end
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

            CASES = Sus::Shared("room redaction cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if RoomRedaction.const_defined?(name, false)
                  include RoomRedaction.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
