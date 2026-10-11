# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::Query}.
        module Query
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

          # v1.1 asked a server about a user and an alias.
          module V1_1
            # A user's profile, as the server which owns them reports it.
            #
            # @parameter user_id [String] the user to ask about.
            # @parameter field [String | nil] one field, or nil for all of them.
            # @returns [Profile] the profile.
            def query_profile(user_id, field: nil)
              parameters = {user_id: user_id, field: field}.compact

              api::Profile.get(@resource.with(path: "#{FEDERATION_V1}/query/profile", parameters: parameters))
            end

            # The room an alias names, and which servers are in it.
            #
            # @parameter room_alias [String] the alias to resolve, e.g. `#general:example.com`.
            # @returns [RoomDirectoryEntry] the room, and who to ask about it.
            def query_room_directory(room_alias)
              parameters = {room_alias: room_alias}

              api::RoomDirectoryEntry.get(@resource.with(path: "#{FEDERATION_V1}/query/directory", parameters: parameters))
            end

            # A query of a kind the specification does not name, which is how it is extended.
            #
            # @parameter query_type [String] the kind of query, e.g. `profile`.
            # @parameter parameters [Hash] whatever that kind of query takes.
            # @returns [QueryResult] whatever it answers.
            def query_info(query_type, **parameters)
              path = "#{FEDERATION_V1}/query/#{::Protocol::URL::Encoding.escape(query_type)}"

              api::QueryResult.get(@resource.with(path: path, parameters: parameters))
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::Profile}.
        module Profile
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # v1.16 let a profile carry unnamed fields.
          module V1_16
            # One field of the profile, named or not.
            #
            # @parameter key [String] the field, e.g. `displayname` or `m.tz`.
            # @returns [Object | nil] its value.
            def field(key)
              self.value[key.to_sym]
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

          # No changes in v1.2.
          module V1_2
          end

          # v1.1 answered with the display name and the avatar.
          module V1_1
            # @returns [String | nil] the name the user goes by.
            def displayname
              self.value[:displayname]
            end

            # @returns [String | nil] the `mxc://` URI of the user's avatar.
            def avatar_url
              self.value[:avatar_url]
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::RoomDirectoryEntry}.
        module RoomDirectoryEntry
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

          # v1.1 answered with the room and the servers in it.
          module V1_1
            # @returns [String | nil] the room the alias names.
            def room_id
              self.value[:room_id]
            end

            # The servers worth asking to join, which is what makes the answer useful.
            #
            # @returns [Array(String)] the servers which are in the room.
            def servers
              self.value[:servers] || []
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::QueryResult}.
        module QueryResult
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

          # v1.1 left a query's answer shapeless.
          module V1_1
            # The specification does not say what an unnamed kind of query answers.
            #
            # @parameter key [String] the field to read.
            # @returns [Object | nil] its value.
            def field(key)
              self.value[key.to_sym]
            end
          end
        end
      end
    end
  end
end
