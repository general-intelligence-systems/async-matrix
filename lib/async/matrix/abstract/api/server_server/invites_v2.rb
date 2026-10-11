# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::InvitesV2}.
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
            # Ask another server to let one of its users know they are invited.
            #
            # The room version is given, because the event cannot be read without it.
            #
            # @parameter room_id [String] the room the invite is to.
            # @parameter event_id [String] the ID of the signed invite event.
            # @parameter event [Hash] the signed invite event.
            # @parameter room_version [String] the version of the room.
            # @parameter invite_room_state [Array(Hash) | nil] enough state to show the room.
            # @returns [InvitedEvent] the event, signed by both servers.
            def send_invite_v2(room_id, event_id, event, room_version:, invite_room_state: nil)
              path = "#{FEDERATION_V2}/invite/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"
              payload = {room_version: room_version, event: event, invite_room_state: invite_room_state}.compact

              api::InvitedEvent.put(@resource.with(path: path), payload)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::InvitedEvent}.
        module InvitedEvent
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

          # v1.1 answered with the event both servers signed.
          module V1_1
            # The invited server signs the event too, which is how it says it accepted it.
            #
            # @returns [Hash] the event, as both servers have it.
            def event
              self.value[:event] || {}
            end

            # @returns [Hash] the signatures on the event, by server name.
            def signatures
              self.event[:signatures] || {}
            end

            # Whether a server has signed the event.
            #
            # @parameter server_name [String] the server to look for.
            # @returns [Boolean] whether it signed.
            def signed_by?(server_name)
              self.signatures.key?(server_name.to_sym)
            end
          end
        end
      end
    end
  end
end
