# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::Knocks}.
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
            # A knock event for the room, built by the server which has it.
            #
            # A knock asks to be let in, which only some rooms allow.
            #
            # @parameter room_id [String] the room to knock on.
            # @parameter user_id [String] the user knocking, who belongs to the asking server.
            # @parameter versions [Array(String)] the room versions the asking server understands.
            # @returns [MembershipTemplate] the event to sign and send back.
            def make_knock(room_id, user_id, versions: [])
              path = "#{FEDERATION_V1}/make_knock/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(user_id)}"
              query = api::Parameters.repeated(:ver, versions)

              api::MembershipTemplate.get(@resource.with(path: api::Parameters.path(path, query)))
            end

            # Send the signed knock event back, and be told enough to show the room.
            #
            # @parameter room_id [String] the room being knocked on.
            # @parameter event_id [String] the ID of the signed event.
            # @parameter event [Hash] the signed knock event.
            # @returns [KnockedRoom] what the room will say about itself.
            def send_knock(room_id, event_id, event)
              path = "#{FEDERATION_V1}/send_knock/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"

              api::KnockedRoom.put(@resource.with(path: path), event)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::KnockedRoom}.
        module KnockedRoom
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

          # v1.1 answered with enough state to show the room.
          module V1_1
            # Enough of the room to show somebody who is not in it: its name, avatar and rules.
            #
            # @returns [Array(Hash)] the stripped state of the room.
            def knock_room_state
              self.value[:knock_room_state] || []
            end

            # @returns [Array(String)] the types of the state events.
            def types
              self.knock_room_state.map{|event| event[:type]}
            end

            # @returns [Boolean] whether the room said nothing about itself.
            def empty?
              self.knock_room_state.empty?
            end
          end
        end
      end
    end
  end
end
