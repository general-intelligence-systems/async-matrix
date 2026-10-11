# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::LeavingV2}.
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
            # Send the signed leave event back, which is accepted or refused.
            #
            # @parameter room_id [String] the room being left.
            # @parameter event_id [String] the ID of the signed event.
            # @parameter event [Hash] the signed leave event.
            # @returns [Representation] the empty answer.
            def send_leave_v2(room_id, event_id, event)
              path = "#{FEDERATION_V2}/send_leave/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"

              api::Representation.put(@resource.with(path: path), event)
            end
          end
        end
      end
    end
  end
end
