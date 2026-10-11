# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Knocking}.
        module Knocking
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

          # v1.14 removed `server_name`, leaving `via` alone.
          module V1_14
            # Knock on a room, which asks its members to invite you.
            #
            # @parameter room_id_or_alias [String] the room to knock on, by ID or by alias.
            # @parameter via [Array(String) | nil] the servers to knock through.
            # @parameter reason [String | nil] what to record as the reason.
            # @returns [RoomReference] the room knocked on.
            def knock_room(room_id_or_alias, via: nil, reason: nil)
              payload = {reason: reason}.compact
              parameters = {via: via}.compact

              api::RoomReference.post(@resource.with(path: "#{V3}/knock/#{::Protocol::URL::Encoding.escape(room_id_or_alias)}", parameters: parameters), payload)
            end
          end

          # No changes in v1.13.
          module V1_13
          end

          # v1.12 added `via` alongside `server_name`.
          module V1_12
            # Knock on a room, which asks its members to invite you.
            #
            # @parameter room_id_or_alias [String] the room to knock on, by ID or by alias.
            # @parameter server_name [Array(String) | nil] the servers to knock through.
            # @parameter via [Array(String) | nil] the servers to knock through.
            # @parameter reason [String | nil] what to record as the reason.
            # @returns [RoomReference] the room knocked on.
            def knock_room(room_id_or_alias, server_name: nil, via: nil, reason: nil)
              payload = {reason: reason}.compact
              parameters = {server_name: server_name, via: via}.compact

              api::RoomReference.post(@resource.with(path: "#{V3}/knock/#{::Protocol::URL::Encoding.escape(room_id_or_alias)}", parameters: parameters), payload)
            end
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
