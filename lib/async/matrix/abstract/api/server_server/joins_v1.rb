# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::JoinsV1}.
        module JoinsV1
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 withdrew the first version of the send.
          module V1_18
            extend Removals

            removed :send_join_v1, use: :send_join_v2
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

          # v1.1 joined a room through another server.
          module V1_1
            # A join event for the room, built by the server which has it.
            #
            # A server cannot build it itself: it does not know the state to point at.
            #
            # @parameter room_id [String] the room to join.
            # @parameter user_id [String] the user joining, who belongs to the asking server.
            # @parameter versions [Array(String)] the room versions the asking server understands.
            # @returns [MembershipTemplate] the event to sign and send back.
            def make_join(room_id, user_id, versions: [])
              path = "#{FEDERATION_V1}/make_join/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(user_id)}"
              query = api::Parameters.repeated(:ver, versions)

              api::MembershipTemplate.get(@resource.with(path: api::Parameters.path(path, query)))
            end

            # Send the signed join event back, as the first version of the endpoint.
            #
            # @parameter room_id [String] the room being joined.
            # @parameter event_id [String] the ID of the signed event.
            # @parameter event [Hash] the signed join event.
            # @returns [JoinedRoomV1] the state of the room, wrapped in a status.
            def send_join_v1(room_id, event_id, event)
              path = "#{FEDERATION_V1}/send_join/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"

              api::JoinedRoomV1.put(@resource.with(path: path), event)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::MembershipTemplate}.
        module MembershipTemplate
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

          # v1.1 answered with an event to sign.
          module V1_1
            # The version decides how the event is hashed and signed, so it is answered with it.
            #
            # @returns [String | nil] the room version.
            def room_version
              self.value[:room_version]
            end

            # @returns [Hash] the event to sign, which is not signed and has no ID.
            def event
              self.value[:event] || {}
            end

            # @returns [String | nil] the kind of membership the event would set.
            def membership
              self.event.dig(:content, :membership)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::JoinedRoomV1}.
        module JoinedRoomV1
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

          # v1.1 answered with a status beside the body.
          module V1_1
            # The first version answered `[200, {...}]`, which v2 replaced with the body alone.
            #
            # @returns [Hash] the body, whichever way it was wrapped.
            def body
              if self.value.is_a?(Array)
                self.value.last
              else
                self.value
              end
            end

            # @returns [Array(Hash)] the state of the room at the join.
            def state
              self.body[:state] || []
            end

            # @returns [Array(Hash)] the events which authorise that state.
            def auth_chain
              self.body[:auth_chain] || []
            end

            # @returns [Hash] the join event as the room now has it.
            def event
              self.body[:event] || {}
            end
          end
        end
      end
    end
  end
end
