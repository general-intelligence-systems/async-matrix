# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::LeavingV1}.
        module LeavingV1
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 withdrew the first version of the send.
          module V1_18
            extend Removals

            removed :send_leave_v1, use: :send_leave_v2
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

          # v1.1 left a room through another server.
          module V1_1
            # A leave event for the room, built by the server which has it.
            #
            # @parameter room_id [String] the room to leave.
            # @parameter user_id [String] the user leaving, who belongs to the asking server.
            # @returns [MembershipTemplate] the event to sign and send back.
            def make_leave(room_id, user_id)
              path = "#{FEDERATION_V1}/make_leave/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(user_id)}"

              api::MembershipTemplate.get(@resource.with(path: path))
            end

            # Send the signed leave event back, as the first version of the endpoint.
            #
            # @parameter room_id [String] the room being left.
            # @parameter event_id [String] the ID of the signed event.
            # @parameter event [Hash] the signed leave event.
            # @returns [Representation] the empty answer, wrapped in a status.
            def send_leave_v1(room_id, event_id, event)
              path = "#{FEDERATION_V1}/send_leave/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"

              api::Representation.put(@resource.with(path: path), event)
            end
          end
        end
      end
    end
  end
end
