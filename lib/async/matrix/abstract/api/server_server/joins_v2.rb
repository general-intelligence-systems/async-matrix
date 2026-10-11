# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::JoinsV2}.
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

          # v1.1 sent the join without the status wrapper.
          module V1_1
            # Send the signed join event back, and be told the state of the room.
            #
            # @parameter room_id [String] the room being joined.
            # @parameter event_id [String] the ID of the signed event.
            # @parameter event [Hash] the signed join event.
            # @parameter omit_members [Boolean | nil] whether to leave the membership out of the state.
            # @returns [JoinedRoom] the state of the room at the join.
            def send_join_v2(room_id, event_id, event, omit_members: nil)
              path = "#{FEDERATION_V2}/send_join/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"
              parameters = {omit_members: omit_members}.compact

              api::JoinedRoom.put(@resource.with(path: path, parameters: parameters), event)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::JoinedRoom}.
        module JoinedRoom
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
            # A room with many members is a great deal of state, most of it memberships.
            #
            # @returns [Boolean] whether the memberships were left out.
            def members_omitted?
              self.value[:members_omitted] || false
            end

            # Who to ask for the memberships which were left out.
            #
            # @returns [Array(String)] the servers in the room.
            def servers_in_room
              self.value[:servers_in_room] || []
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

          # v1.1 answered with the state of the room.
          module V1_1
            # @returns [Array(Hash)] the state of the room at the join.
            def state
              self.value[:state] || []
            end

            # @returns [Array(Hash)] the events which authorise that state.
            def auth_chain
              self.value[:auth_chain] || []
            end

            # @returns [Hash] the join event as the room now has it.
            def event
              self.value[:event] || {}
            end

            # @returns [Array(String)] the types of the state events.
            def types
              self.state.map{|event| event[:type]}
            end
          end
        end
      end
    end
  end
end
