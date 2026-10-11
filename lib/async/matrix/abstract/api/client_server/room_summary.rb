# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::RoomSummary}.
        module RoomSummary
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

          # v1.15 added the room summary.
          module V1_15
            # What a homeserver will say about a room without joining it.
            #
            # @parameter room_id_or_alias [String] the room to summarise, by ID or by alias.
            # @parameter via [Array(String) | nil] the servers to ask through.
            # @returns [SummarisedRoom] the summary.
            def get_room_summary(room_id_or_alias, via: nil)
              parameters = {via: via}.compact
              path = "#{V1}/room_summary/#{::Protocol::URL::Encoding.escape(room_id_or_alias)}"

              api::SummarisedRoom.get(@resource.with(path: path, parameters: parameters))
            end
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
        end

        # Layers for {ruby Async::Matrix::ClientServer::SummarisedRoom}.
        module SummarisedRoom
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

          # v1.15 added the summary, which describes the room.
          module V1_15
            # @returns [String] the room summarised.
            def room_id
              self.value[:room_id]
            end

            # @returns [String | nil] the name of the room, where it has one.
            def name
              self.value[:name]
            end

            # @returns [String | nil] the topic of the room, where it has one.
            def topic
              self.value[:topic]
            end

            # @returns [String | nil] the alias the room is published under, where it has one.
            def canonical_alias
              self.value[:canonical_alias]
            end

            # @returns [Integer] how many members are joined.
            def num_joined_members
              self.value[:num_joined_members]
            end

            # @returns [String] how a user may join, e.g. `public` or `knock`.
            def join_rule
              self.value[:join_rule]
            end

            # @returns [String | nil] the kind of room it is, e.g. `m.space`.
            def room_type
              self.value[:room_type]
            end

            # @returns [String | nil] the room version it was created at.
            def room_version
              self.value[:room_version]
            end

            # @returns [String | nil] this user's membership of it, where they have one.
            def membership
              self.value[:membership]
            end

            # @returns [String | nil] the `mxc://` URI of the room's avatar, where it has one.
            def avatar_url
              self.value[:avatar_url]
            end

            # @returns [String | nil] the algorithm the room is encrypted with, where it is.
            def encryption
              self.value[:encryption]
            end

            # @returns [Array(String) | nil] the rooms whose members may join, where the join rule restricts it.
            def allowed_room_ids
              self.value[:allowed_room_ids]
            end

            # @returns [Boolean] whether anyone may read the room without joining.
            def world_readable?
              self.value[:world_readable]
            end

            # @returns [Boolean] whether a guest may join.
            def guest_can_join?
              self.value[:guest_can_join]
            end
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
        end
      end
    end
  end
end
